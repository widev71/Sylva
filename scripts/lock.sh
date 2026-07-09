#!/usr/bin/env bash

# Ensure HOME and USER are set if called from systemd/hypridle
export HOME=${HOME:-/home/witya}
export USER=${USER:-witya}

# Source and initialize quickshell dynamic caching
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "lock"

quickshell -p "$HOME/.config/hypr/scripts/quickshell/Lock.qml"

