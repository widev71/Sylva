#!/usr/bin/env bash

STATE_FILE="/tmp/hypr_focus_mode"
SHADER_FILE="$HOME/.config/hypr/shaders/blue_light.frag"

if [ -f "$STATE_FILE" ]; then
    # Disable Focus Mode
    rm "$STATE_FILE"
    
    # Restore Notifications
    dunstctl set-paused false 2>/dev/null
    
    # Restore Hyprland aesthetics
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:drop_shadow 1
    hyprctl keyword decoration:blur:enabled 1
    hyprctl keyword decoration:screen_shader "[[EMPTY]]"
    
    echo "Focus mode OFF"
else
    # Enable Focus Mode
    touch "$STATE_FILE"
    
    # Pause Notifications (Do Not Disturb)
    dunstctl set-paused true 2>/dev/null
    
    # Disable Hyprland aesthetics for maximum focus
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:drop_shadow 0
    hyprctl keyword decoration:blur:enabled 0
    
    # Apply Night Light Shader
    if [ -f "$SHADER_FILE" ]; then
        hyprctl keyword decoration:screen_shader "$SHADER_FILE"
    fi
    
    echo "Focus mode ON"
fi
