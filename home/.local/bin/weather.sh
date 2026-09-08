#!/bin/sh
set -eu

# Fetch weather data from wttr.in
DATA=$(curl -s --max-time 4 "https://wttr.in/?format=j1" 2>/dev/null || true)

# If offline or invalid response, return fallback JSON
if [ -z "$DATA" ] || ! echo "$DATA" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
    echo '{"text": "󰖐 --°C", "tooltip": "No connection"}'
    exit 0
fi

# Weather icons mapping (WWO codes to Nerd Font Day/Night)
get_icon() {
    code="$1"
    is_night="${2:-0}"
    case $code in
        113) # Sunny / Clear
            [ "$is_night" -eq 1 ] && echo "" || echo ""
            ;;
        116) # Partly cloudy
            [ "$is_night" -eq 1 ] && echo "" || echo ""
            ;;
        119|122) # Cloudy / Overcast
            echo ""
            ;;
        143|248|260) # Fog / Mist
            [ "$is_night" -eq 1 ] && echo "" || echo ""
            ;;
        176|263|266|281|284|293|296) # Patchy rain / Drizzle
            [ "$is_night" -eq 1 ] && echo "" || echo ""
            ;;
        299|302|305|308|353|356|359) # Heavy / moderate rain
            echo ""
            ;;
        200|386|389|392|395) # Thunderstorm
            [ "$is_night" -eq 1 ] && echo "" || echo ""
            ;;
        179|182|185|227|230|311|314|317|320|323|326|329|332|335|338|350|362|365|368|371|374|377) # Snow / Ice
            [ "$is_night" -eq 1 ] && echo "" || echo ""
            ;;
        *) # Fallback
            echo ""
            ;;
    esac
}

# Day/night detection (18:00 - 06:00 is night)
HOUR=$(date +%-H)
IS_NIGHT=0
if [ "$HOUR" -lt 6 ] || [ "$HOUR" -ge 18 ]; then
    IS_NIGHT=1
fi

# Extract current weather information
TEMP=$(echo "$DATA" | jq -r '.current_condition[0].temp_C // "--"')
CODE=$(echo "$DATA" | jq -r '.current_condition[0].weatherCode // ""')
ICON=$(get_icon "$CODE" "$IS_NIGHT")

# Extract current details for tooltip with Pango markup escaping and fallbacks
CURRENT_INFO=$(echo "$DATA" | jq -r '
  .current_condition[0] as $c |
  (($c.weatherDesc[0].value // "N/A") | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")) as $desc |
  "<b>Current:</b> \($desc) (\($c.temp_C // "--")°C, Feels like: \($c.FeelsLikeC // "--")°C)\n" +
  " Wind: \($c.winddir16Point // "N/A") \($c.windspeedKmph // "--") km/h |  Humidity: \($c.humidity // "--")%\n\n" +
  "<b>Forecast:</b>"
')

# Build 3-day forecast lines with icons
FORECAST=""
while read -r d_date d_min d_max d_code; do
    [ -n "$d_date" ] || continue
    d_label=$(date -d "$d_date" "+%a (%d/%m)" 2>/dev/null || echo "$d_date")
    d_icon=$(get_icon "$d_code")
    FORECAST="${FORECAST}\n• ${d_label}: ${d_icon}  ${d_min}°C - ${d_max}°C"
done << EOF
$(echo "$DATA" | jq -r '.weather[] | "\(.date) \(.mintempC // "--") \(.maxtempC // "--") \(.hourly[4].weatherCode // .hourly[0].weatherCode // "")"')
EOF

TOOLTIP="${CURRENT_INFO}${FORECAST}"

# Output single-line JSON for Waybar
jq -c -n \
  --arg text "$ICON ${TEMP}°C" \
  --arg tooltip "$(printf "%b" "$TOOLTIP")" \
  --arg class "weather-$CODE" \
  '{text: $text, tooltip: $tooltip, class: $class}'
