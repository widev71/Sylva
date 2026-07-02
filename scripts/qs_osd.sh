#!/usr/bin/env bash

ACTION=$1

if [ "$ACTION" == "vol_up" ]; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    VAL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oE "[0-9.]+" | head -n 1)
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" && echo "1" || echo "0")
    echo "volume|$VAL|$MUTED" > /tmp/qs_osd_val
elif [ "$ACTION" == "vol_down" ]; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    VAL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oE "[0-9.]+" | head -n 1)
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" && echo "1" || echo "0")
    echo "volume|$VAL|$MUTED" > /tmp/qs_osd_val
elif [ "$ACTION" == "vol_mute" ]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    VAL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oE "[0-9.]+" | head -n 1)
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" && echo "1" || echo "0")
    echo "volume|$VAL|$MUTED" > /tmp/qs_osd_val
elif [ "$ACTION" == "mic_mute" ]; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    VAL=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -oE "[0-9.]+" | head -n 1)
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED" && echo "1" || echo "0")
    echo "mic|$VAL|$MUTED" > /tmp/qs_osd_val
elif [ "$ACTION" == "bright_up" ]; then
    brightnessctl s 5%+
    VAL=$(brightnessctl g)
    MAX=$(brightnessctl m)
    PCT=$(awk "BEGIN {print $VAL / $MAX}")
    echo "brightness|$PCT|0" > /tmp/qs_osd_val
elif [ "$ACTION" == "bright_down" ]; then
    brightnessctl s 5%-
    VAL=$(brightnessctl g)
    MAX=$(brightnessctl m)
    PCT=$(awk "BEGIN {print $VAL / $MAX}")
    echo "brightness|$PCT|0" > /tmp/qs_osd_val
fi
