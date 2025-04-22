#!/bin/bash

# Configuration
OPENSPOT_IP="192.168.10.185" 
PASSWORD=""  # Leave empty, if you didn't set one
CALLSIGN="DO9RE"  # Guess what?
INTERVAL=5  # Interval in seconds, how often tg is checked

# API-paths
GET_TOKEN_PATH="/gettok.cgi"
LOGIN_PATH="/login.cgi"
STATUS_PATH="/status.cgi"

# Status variables
AUTH_TOKEN=""
LAST_TALKGROUP=""

fetch_token() {
    echo "Getting Session-Token..."
    response=$(curl -s "http://$OPENSPOT_IP$GET_TOKEN_PATH")
    TOKEN=$(echo "$response" | jq -r '.token')

    if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
        echo "Error: Unable to fetch session token. Answer: $response"
        exit 1
    fi
}

login() {
    echo "Login, to get JWT ..."
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
    MESSAGE="$1"
    echo "Send message: $MESSAGE"
    toot post "$MESSAGE"
}

# Main script
echo "Start talkgroup-monitoring..."

while true; do
    if [ -z "$AUTH_TOKEN" ]; then
        fetch_token
        login
    fi

    fetch_status

    # Special case TG 4000
    if [ "$TALKGROUP" == "4000" ]; then
        if [ "$LAST_TALKGROUP" != "4000" ] && [ -n "$LAST_TALKGROUP" ]; then
            MESSAGE="$CALLSIGN left talkgroup $LAST_TALKGROUP."
            send_mastodon_message "$MESSAGE"
        fi
        LAST_TALKGROUP=""  
        echo "(4000) recognized."
    # Check, if talkgroup changed
    elif [ "$TALKGROUP" != "$LAST_TALKGROUP" ]; then
        echo "Talkgroup changed: $LAST_TALKGROUP -> $TALKGROUP"
        LAST_TALKGROUP="$TALKGROUP"
        
        # Send message, if we have a valid talk group
        if [ "$TALKGROUP" != "null" ] && [ -n "$TALKGROUP" ]; then
            MESSAGE="$CALLSIGN is now available in Talkgroup $TALKGROUP."
            send_mastodon_message "$MESSAGE"
        fi
    else
        echo "No change in talkgroup ($TALKGROUP)."
    fi

    # Warte das eingestellte Intervall
    sleep $INTERVAL
done
