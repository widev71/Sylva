#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CACHING & MIGRATION
# -----------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "weather"

export LC_ALL=C

cache_dir="$QS_CACHE_WEATHER"
json_file="${cache_dir}/weather.json"
view_file="${cache_dir}/view_id"
ENV_FILE="$(dirname "$0")/.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

UNIT="${OPENWEATHER_UNIT:-metric}"
case "$UNIT" in
    "imperial") UNIT_SYM="°F"; TEMP_UNIT="fahrenheit"; WIND_UNIT="mph" ;;
    *) UNIT_SYM="°C"; TEMP_UNIT="celsius"; WIND_UNIT="kmh" ;;
esac

mkdir -p "${cache_dir}"

get_icon_and_quote() {
    case $1 in
        0|1) icon=""; quote="Clear" ;;
        2|3) icon=""; quote="Cloudy" ;;
        45|48) icon="󰖑"; quote="Fog" ;;
        51|53|55|56|57) icon="󰖗"; quote="Drizzle" ;;
        61|63|65|66|67) icon="󰖗"; quote="Rain" ;;
        71|73|75|77|85|86) icon=""; quote="Snow" ;;
        80|81|82) icon="󰖗"; quote="Showers" ;;
        95|96|99) icon=""; quote="Storm" ;;
        *) icon=""; quote="Unknown" ;;
    esac
    echo "$icon|$quote"
}

get_hex() {
    case $1 in
        0|1) echo "#f9e2af" ;;
        2|3) echo "#bac2de" ;;
        45|48) echo "#84afdb" ;;
        51|53|55|56|57|61|63|65|66|67|80|81|82) echo "#74c7ec" ;;
        95|96|99) echo "#f9e2af" ;;
        71|73|75|77|85|86) echo "#cdd6f4" ;;
        *) echo "#cdd6f4" ;;
    esac
}

write_dummy_data() {
    final_json="["
    for i in {0..4}; do
        future_date=$(date -d "+$i days")
        f_day=$(date -d "$future_date" "+%a")
        f_full_day=$(date -d "$future_date" "+%A")
        f_date_num=$(date -d "$future_date" "+%d %b")
        
        final_json="${final_json} {
            \"id\": \"${i}\", \"day\": \"${f_day}\", \"day_full\": \"${f_full_day}\", \"date\": \"${f_date_num}\",
            \"max\": \"0.0\", \"min\": \"0.0\", \"feels_like\": \"0.0\", \"wind\": \"0\", \"humidity\": \"0\", \"pop\": \"0\",
            \"icon\": \"\", \"hex\": \"#cdd6f4\", \"desc\": \"No Data\",
            \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"\", \"hex\": \"#cdd6f4\"}]
        },"
    done
    final_json="${final_json%,}]"
    echo "{ \"current_temp\": \"0.0\", \"current_icon\": \"\", \"current_hex\": \"#cdd6f4\", \"forecast\": ${final_json} }" > "${json_file}"
}

get_data() {
    LAT="$OPENMETEO_LAT"
    LON="$OPENMETEO_LON"

    if [ -z "$LAT" ] || [ -z "$LON" ]; then
        # Try getting location from IP
        IP_JSON=$(curl -s --max-time 3 "https://ipinfo.io/json")
        if [ -n "$IP_JSON" ] && echo "$IP_JSON" | grep -q '"loc"'; then
            LOC=$(echo "$IP_JSON" | jq -r '.loc')
            LAT=$(echo "$LOC" | cut -d',' -f1)
            LON=$(echo "$LOC" | cut -d',' -f2)
            CITY=$(echo "$IP_JSON" | jq -r '.city')
            REGION=$(echo "$IP_JSON" | jq -r '.region')
            LOC_STRING="${CITY}, ${REGION}"
        else
            # Denpasar default
            LAT="-8.65"
            LON="115.2167"
            LOC_STRING="Denpasar, Bali"
        fi
    else
        LOC_STRING="Latitude ${LAT}"
    fi

    if [ -n "$WEATHER_LOC_NAME" ]; then
        LOC_STRING="$WEATHER_LOC_NAME"
    fi

    url="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset&hourly=temperature_2m,weather_code&timezone=auto&temperature_unit=${TEMP_UNIT}&wind_speed_unit=${WIND_UNIT}"
    raw_api=$(curl -sf "$url")
    
    if [ -z "$raw_api" ]; then
        if [ ! -f "$json_file" ]; then write_dummy_data; fi
        return
    fi

    # Parse Current Weather
    c_temp=$(echo "$raw_api" | jq -r '.current.temperature_2m')
    c_temp=$(printf "%.1f" "$c_temp")
    c_code=$(echo "$raw_api" | jq -r '.current.weather_code')
    c_icon=$(get_icon_and_quote "$c_code" | cut -d'|' -f1)
    c_hex=$(get_hex "$c_code")

    # Parse 5-day forecast
    final_json="["
    for i in {0..4}; do
        f_code=$(echo "$raw_api" | jq -r ".daily.weather_code[$i]")
        f_max=$(echo "$raw_api" | jq -r ".daily.temperature_2m_max[$i]")
        f_min=$(echo "$raw_api" | jq -r ".daily.temperature_2m_min[$i]")
        f_feels=$(echo "$raw_api" | jq -r ".daily.apparent_temperature_max[$i]")
        f_pop=$(echo "$raw_api" | jq -r ".daily.precipitation_probability_max[$i]")
        f_wind=$(echo "$raw_api" | jq -r ".daily.wind_speed_10m_max[$i]" | awk '{print int($1+0.5)}')
        
        f_uv=$(echo "$raw_api" | jq -r ".daily.uv_index_max[$i]")
        f_sunrise_raw=$(echo "$raw_api" | jq -r ".daily.sunrise[$i]")
        f_sunset_raw=$(echo "$raw_api" | jq -r ".daily.sunset[$i]")
        f_sunrise=$(date -d "$f_sunrise_raw" "+%H:%M" 2>/dev/null || echo "06:00")
        f_sunset=$(date -d "$f_sunset_raw" "+%H:%M" 2>/dev/null || echo "18:00")
        
        # Open-Meteo doesn't have daily humidity by default, we'll just mock it or grab average from hourly if needed, 
        # but 70% is fine for Bali placeholder
        f_hum="70"

        d_str=$(echo "$raw_api" | jq -r ".daily.time[$i]")
        f_day=$(date -d "$d_str" "+%a")
        f_full_day=$(date -d "$d_str" "+%A")
        f_date_num=$(date -d "$d_str" "+%d %b")

        icon_data=$(get_icon_and_quote "$f_code")
        f_icon=$(echo "$icon_data" | cut -d'|' -f1)
        f_desc=$(echo "$icon_data" | cut -d'|' -f2)
        f_hex=$(get_hex "$f_code")

        # Parse Hourly
        hourly_json="["
        start_idx=$((i * 24))
        end_idx=$((start_idx + 23))
        
        # We sample 4-5 points for the day to keep JSON small
        for j in $(seq $start_idx 4 $end_idx); do
            h_time_str=$(echo "$raw_api" | jq -r ".hourly.time[$j]")
            h_time=$(date -d "$h_time_str" "+%H:%M")
            h_temp=$(echo "$raw_api" | jq -r ".hourly.temperature_2m[$j]")
            h_code=$(echo "$raw_api" | jq -r ".hourly.weather_code[$j]")
            
            h_icon=$(get_icon_and_quote "$h_code" | cut -d'|' -f1)
            h_hex=$(get_hex "$h_code")
            
            hourly_json="${hourly_json} {\"time\": \"${h_time}\", \"temp\": \"${h_temp}\", \"icon\": \"${h_icon}\", \"hex\": \"${h_hex}\"},"
        done
        hourly_json="${hourly_json%,}]"

        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"uv\": \"${f_uv}\",
            \"sunrise\": \"${f_sunrise}\",
            \"sunset\": \"${f_sunset}\",
            \"max\": \"${f_max}\",
            \"min\": \"${f_min}\",
            \"feels_like\": \"${f_feels}\",
            \"wind\": \"${f_wind}\",
            \"humidity\": \"${f_hum}\",
            \"pop\": \"${f_pop}\",
            \"icon\": \"${f_icon}\",
            \"hex\": \"${f_hex}\",
            \"desc\": \"${f_desc}\",
            \"hourly\": ${hourly_json}
        },"
    done
    final_json="${final_json%,}]"

    echo "{ \"location\": \"${LOC_STRING}\", \"current_temp\": \"${c_temp}\", \"current_icon\": \"${c_icon}\", \"current_hex\": \"${c_hex}\", \"forecast\": ${final_json} }" > "${json_file}"
}

if [[ "$1" == "--getdata" ]]; then
    get_data
elif [[ "$1" == "--json" ]]; then
    CACHE_LIMIT=900
    if [ -f "$json_file" ]; then
        file_time=$(stat -c %Y "$json_file")
        current_time=$(date +%s)
        diff=$((current_time - file_time))
        if [ $diff -gt $CACHE_LIMIT ]; then
            touch "$json_file"
            get_data &
        fi
        cat "$json_file"
    else
        get_data
        cat "$json_file"
    fi
elif [[ "$1" == "--view-listener" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    tail -F "$view_file"
elif [[ "$1" == "--nav" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    current=$(cat "$view_file")
    direction=$2
    if [[ "$direction" == "next" ]] && [ "$current" -lt 4 ]; then
        echo $((current + 1)) > "$view_file"
    elif [[ "$direction" == "prev" ]] && [ "$current" -gt 0 ]; then
        echo $((current - 1)) > "$view_file"
    fi
elif [[ "$1" == "--icon" ]]; then
    cat "$json_file" | jq -r '.forecast[0].icon'
elif [[ "$1" == "--temp" ]]; then 
    echo "$(cat "$json_file" | jq -r '.forecast[0].max')${UNIT_SYM}"
elif [[ "$1" == "--hex" ]]; then 
    cat "$json_file" | jq -r '.forecast[0].hex'
elif [[ "$1" == "--current-icon" ]]; then
    icon=$(cat "$json_file" | jq -r '.current_icon // empty')
    if [[ -z "$icon" ]]; then get_data; icon=$(cat "$json_file" | jq -r '.current_icon'); fi
    echo "$icon"
elif [[ "$1" == "--current-temp" ]]; then 
    t=$(cat "$json_file" | jq -r '.current_temp // empty')
    if [[ -z "$t" ]]; then get_data; t=$(cat "$json_file" | jq -r '.current_temp'); fi
    echo "${t}${UNIT_SYM}"
elif [[ "$1" == "--current-hex" ]]; then
    hex=$(cat "$json_file" | jq -r '.current_hex // empty')
    if [[ -z "$hex" ]]; then get_data; hex=$(cat "$json_file" | jq -r '.current_hex'); fi
    echo "$hex"
fi
