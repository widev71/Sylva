#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../../caching.sh"
qs_ensure_cache "network"

CACHE_DIR="$QS_CACHE_NETWORK"
mkdir -p "$CACHE_DIR"

if ! ls -1d /sys/class/net/*/wireless &>/dev/null; then
    echo '{ "present": false, "power": "off", "connected": null, "networks": [], "interfaces": [], "active_interface": "" }'
    exit 0
fi

POWER=$(LC_ALL=C nmcli radio wifi)

if [[ "$POWER" == "disabled" ]]; then
    echo '{ "present": true, "power": "off", "connected": null, "networks": [], "interfaces": [], "active_interface": "" }'
    exit 0
fi

get_icon() {
    local signal=$1
    if [[ -z "$signal" ]]; then echo "󰤯"; return; fi
    if [[ $signal -ge 80 ]]; then echo "󰤨";
    elif [[ $signal -ge 60 ]]; then echo "󰤥";
    elif [[ $signal -ge 40 ]]; then echo "󰤢";
    elif [[ $signal -ge 20 ]]; then echo "󰤟";
    else echo "󰤯"; fi
}

# Fetch all wifi interfaces
ALL_IFACES=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d | awk -F: '$2=="wifi"{print $1}')
IFACES_JSON=$(echo "$ALL_IFACES" | awk 'BEGIN {printf "["} {if (NR>1) printf ","; printf "\"%s\"", $1} END {printf "]"}')

SELECTED_IFACE=""
if [ -f "$CACHE_DIR/wifi_iface" ]; then
    SELECTED_IFACE=$(cat "$CACHE_DIR/wifi_iface")
fi

# Ensure selected interface is valid
IFACE_VALID=false
for iface in $ALL_IFACES; do
    if [ "$iface" == "$SELECTED_IFACE" ]; then IFACE_VALID=true; break; fi
done

if [ "$IFACE_VALID" = false ]; then
    SELECTED_IFACE=$(echo "$ALL_IFACES" | head -n 1)
    echo "$SELECTED_IFACE" > "$CACHE_DIR/wifi_iface"
fi

if [ -z "$SELECTED_IFACE" ]; then
    echo '{ "present": true, "power": "on", "connected": null, "networks": [], "interfaces": [], "active_interface": "" }'
    exit 0
fi

CURRENT_RAW=$(LC_ALL=C nmcli -t -f active,ssid,signal,security device wifi list ifname "$SELECTED_IFACE" | awk -F: '$1=="yes"{print; exit}')

if [[ -n "$CURRENT_RAW" ]]; then
    IFS=':' read -r active ssid signal security <<< "$CURRENT_RAW"
    icon=$(get_icon "$signal")
    
    SAFE_SSID="${ssid//[^a-zA-Z0-9]/_}"
    CACHE_FILE="$CACHE_DIR/wifi_$SAFE_SSID"
    
    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE"
    fi
    
    if [ -z "$IP" ] || [ "$IP" == "No IP" ] || [ -z "$FREQ" ]; then
        IP=$(ip -4 addr show dev "$SELECTED_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [ -z "$IP" ] && IP="No IP"
        
        FREQ=$(iw dev "$SELECTED_IFACE" link 2>/dev/null | awk '/freq:/ {print $2}')
        [ -n "$FREQ" ] && FREQ="${FREQ} MHz" || FREQ="Unknown"
        
        echo "IP=\"$IP\"" > "$CACHE_FILE"
        echo "FREQ=\"$FREQ\"" >> "$CACHE_FILE"
    fi

    ssid_esc="${ssid//\"/\\\"}"
    sec_esc="${security//\"/\\\"}"
    icon_esc="${icon//\"/\\\"}"
    CONNECTED_JSON="{\"id\":\"$ssid_esc\",\"ssid\":\"$ssid_esc\",\"icon\":\"$icon_esc\",\"signal\":\"$signal\",\"security\":\"$sec_esc\",\"ip\":\"$IP\",\"freq\":\"$FREQ\"}"
else
    ssid=""
    CONNECTED_JSON="null"
fi

NETWORKS_JSON=$(LC_ALL=C nmcli -t -f active,ssid,signal,security device wifi list ifname "$SELECTED_IFACE" --rescan no | awk -F: -v conn="$ssid" '
    $2 != "" && $2 != conn && !seen[$2]++ {
        ssid=$2; signal=$3; security=$4;
        gsub(/"/, "\\\"", ssid);
        gsub(/"/, "\\\"", security);
        
        if (signal >= 80) icon="󰤨";
        else if (signal >= 60) icon="󰤥";
        else if (signal >= 40) icon="󰤢";
        else if (signal >= 20) icon="󰤟";
        else icon="󰤯";
        
        printf "{\"id\":\"%s\",\"ssid\":\"%s\",\"icon\":\"%s\",\"signal\":\"%s\",\"security\":\"%s\"}\n", ssid, ssid, icon, signal, security
    }
' | head -n 24 | paste -sd, -)

if [ -z "$NETWORKS_JSON" ]; then
    NETWORKS_JSON="[]"
else
    NETWORKS_JSON="[$NETWORKS_JSON]"
fi

echo "{\"present\":true,\"power\":\"on\",\"connected\":$CONNECTED_JSON,\"networks\":$NETWORKS_JSON,\"interfaces\":$IFACES_JSON,\"active_interface\":\"$SELECTED_IFACE\"}"
