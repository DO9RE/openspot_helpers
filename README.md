# OpenSpot_helpers

This project is a collection of small scripts that I find useful for working with OpenSpot.

## tg_mastodon_push.sh

The `tg_mastodon_push` script monitors the OpenSpot to determine which Talkgroup is currently set and pushes this Talkgroup in a message to Mastodon.

### Requirements

- **JQ**: This tool is required to process JSON data. Make sure it is installed on your system.
- **TOOT**: A command-line client for Mastodon is needed to send messages. Ensure that TOOT is installed and configured.

### Installation

1. Install JQ:
   ```
   sudo apt install jq
   ```

2. Install TOOT:
   ```
   sudo apt install toot
   ```

### Usage

Configure the parameters and run the script to start monitoring the OpenSpot and pushing Talkgroup updates to Mastodon.

```
./tg_mastodon_push.sh
```

You can also run the script in Background or with a cronjob. 
Ensure that both JQ and TOOT are properly installed and configured before running the script.

