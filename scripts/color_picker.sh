#!/bin/bash
exec > /tmp/color_picker.log 2>&1
echo "Starting color picker"
sleep 0.5

# hyprpicker: -a = auto copy, -n = no notif (kita kirim sendiri)
color=$(hyprpicker 2>&1)
echo "Color: '$color'"

if [ -z "$color" ] || [[ "$color" == *"Error"* ]] || [[ "$color" == *"error"* ]]; then
    echo "hyprpicker failed"
    exit 1
fi

echo "$color" | tr -d '\n' | wl-copy
notify-send -a Quickshell -i color-select "Color Picked 🎨" "$color"
echo "Done"
