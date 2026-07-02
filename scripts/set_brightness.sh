#!/bin/bash
TARGET=$1
# Ensure TARGET is within 0-100
if [ "$TARGET" -lt 0 ]; then TARGET=0; fi
if [ "$TARGET" -gt 100 ]; then TARGET=100; fi

# Update cache so UI doesn't bounce while ddcutil runs
echo "$TARGET" > /tmp/ddcutil_brightness_cache

if brightnessctl -m 2>/dev/null | grep -q "backlight"; then
    brightnessctl set "${TARGET}%"
else
    # Use --noverify to speed it up slightly and avoid waiting for DDC/CI readback
    ddcutil setvcp 10 "$TARGET" --noverify
fi
