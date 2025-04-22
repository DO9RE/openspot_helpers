#!/bin/bash

# Configuration
OPENSPOT_IP="192.168.10.185"  
PASSWORD=""  
CALLSIGN="DO9RE"  
DMR_ID=2632260
INTERVAL=10

GET_TOKEN_PATH="/gettok.cgi"
LOGIN_PATH="/login.cgi"
STATUS_PATH="/status.cgi"

AUTH_TOKEN=""
LAST_TALKGROUP="null"

fetch_token() {
  echo "Get Session-Token..."
  response=$(curl -s "http://$OPENSPOT_IP$GET_TOKEN_PATH")
  TOKEN=$(echo "$response" | jq -r '.token')

  if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Unable to fetch session-token. Answer: $response"
    exit 1
  fi
}

login() {
  echo "Login, to fetch JWT..."
  DIGEST=$(echo -n "$TOKEN$PASSWORD" | sha256sum | awk '{print $1}')
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"token\":\"$TOKEN\",\"digest\":\"$DIGEST\"}" "http://$OPENSPOT_IP$LOGIN_PATH")
  AUTH_TOKEN=$(echo "$response" | jq -r '.jwt')

  if [ -z "$AUTH_TOKEN" ] || [ "$AUTH_TOKEN" == "null" ]; then
    echo "Error: Login failed. Answer: $response"
    exit 1
  fi
}

fetch_status() {
  response=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" "http://$OPENSPOT_IP$STATUS_PATH")
  TALKGROUP=$(echo "$response" | jq -r '.callinfo[0][0]')
}

send_mastodon_message() {
  MESSAGE="$CALLSIGN is now available in talkgroup $TALKGROUP."
  echo "Send message: $MESSAGE"
  toot post "$MESSAGE"
}

TALKGROUP="null"
echo "Start talkgroup-monitoring..."

while true; do
  if [ -z "$AUTH_TOKEN" ]; then
    fetch_token
    login
  fi

  fetch_status

  if [ "$TALKGROUP" != "$LAST_TALKGROUP" ]; then
    echo "Talkgroup changed: $LAST_TALKGROUP -> $TALKGROUP"
    LAST_TALKGROUP="$TALKGROUP"
        
    if [ "$TALKGROUP" != "null" ] && [ $TALKGROUP != $DMR_ID ] && [ $TALKGROUP != 4000 ] && [ -n "$TALKGROUP" ]; then
      send_mastodon_message
    fi
  else
    echo "No change in Talkgroup $TALKGROUP."
  fi

  sleep $INTERVAL
done
