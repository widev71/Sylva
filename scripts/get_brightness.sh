#!/bin/bash
b=$(brightnessctl -m 2>/dev/null | head -n1 | grep -i "backlight" | awk -F, '{print substr($4, 1, length($4)-1)}')
if [ -n "$b" ]; then
    echo "$b"
else
    # Cache ddcutil output for 5 seconds to avoid freezing the system
    CACHE_FILE="/tmp/ddcutil_brightness_cache"
    if [ -f "$CACHE_FILE" ] && [ $(expr $(date +%s) - $(stat -c %Y "$CACHE_FILE")) -lt 5 ]; then
        cat "$CACHE_FILE"
    else
        val=$(ddcutil getvcp 10 --terse 2>/dev/null | awk '{print $4}')
        if [ -n "$val" ]; then
            echo "$val" > "$CACHE_FILE"
            echo "$val"
        else
            echo "0"
        fi
    fi
fi
