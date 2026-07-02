#!/usr/bin/env bash

update_tz() {
    TZ=$(curl -s --max-time 5 https://ipinfo.io/timezone)
    if [ -n "$TZ" ]; then
        timedatectl set-timezone "$TZ"
        echo "$(date): Updated timezone to $TZ"
    fi
}

# Run once at startup
update_tz

# Monitor for network connection events
nmcli monitor | while read -r line; do
    if echo "$line" | grep -q "connected"; then
        # Wait a few seconds for network to stabilize before querying API
        sleep 5
        update_tz
    fi
done
