#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"

# Check interval in seconds (600s = 10 minutes)
INTERVAL=600

# Cache file to prevent notification spam if the script is restarted
CACHE_FILE="$QS_CACHE_UPDATER/notified_version"
# State file to tell the topbar to show the update button
PENDING_FILE="$QS_CACHE_UPDATER/update_pending"

REPO="widev71/Sylva"
BRANCH="main"

while true; do
    # Fetch local last commit SHA (stored when last updated)
    LOCAL_SHA=$(source ~/.local/state/imperative-dots-version 2>/dev/null && echo "$LAST_COMMIT")
    LOCAL_SHA=${LOCAL_SHA:-"unknown"}

    # Fetch latest remote commit SHA from Sylva
    REMOTE_SHA=$(curl -m 5 -s "https://api.github.com/repos/${REPO}/commits/${BRANCH}" | grep '"sha"' | head -1 | cut -d'"' -f4)

    # Check if we got valid responses and they don't match
    if [[ -n "$REMOTE_SHA" && "$LOCAL_SHA" != "unknown" && "$LOCAL_SHA" != "$REMOTE_SHA" ]]; then

        # Signal the topbar to show the update icon
        touch "$PENDING_FILE"

        # Only send the notification if we haven't notified about this specific commit yet
        if [[ ! -f "$CACHE_FILE" ]] || [[ "$(cat "$CACHE_FILE")" != "$REMOTE_SHA" ]]; then

            # Cache the SHA so we don't spam the user every 10 minutes
            echo "$REMOTE_SHA" > "$CACHE_FILE"

            notify-send -t 15000 -a 'Sylva' -u normal 'Update Available' "New updates are available! Click the update icon in the topbar to install."
        fi
    else
        # Self-healing: if up to date or offline, clear the pending flag
        rm -f "$PENDING_FILE"
    fi

    sleep "$INTERVAL"
done
