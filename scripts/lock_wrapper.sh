#!/bin/bash
# 1. Run the quickshell lock overlay
quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml

# 2. Check if the lock screen exited successfully (0 = unlocked)
# We can just run the welcome overlay afterwards.
if [ $? -eq 0 ]; then
    quickshell -p ~/.config/hypr/scripts/quickshell/WelcomeOverlay.qml &
fi
