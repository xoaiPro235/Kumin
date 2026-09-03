#!/bin/sh
set -eu


current=$(powerprofilesctl get)

option_perf="󰓅  Performance"
option_bal="󰾆  Balanced"
option_save="  Power-saver"

case "$current" in
    performance) option_perf="$option_perf  ●" ;;
    balanced)    option_bal="$option_bal  ●" ;;
    power-saver) option_save="$option_save  ●" ;;
esac

chosen=$(printf '%s\n' "$option_perf" "$option_bal" "$option_save" | rofi -dmenu -i -p "Power Profile ($current)")

case "$chosen" in
    "$option_perf")
        powerprofilesctl set performance
        notify-send "Power Profile" "Switched to Performance mode"
        ;;
    "$option_bal")
        powerprofilesctl set balanced
        notify-send "Power Profile" "Switched to Balanced mode"
        ;;
    "$option_save")
        powerprofilesctl set power-saver
        notify-send "Power Profile" "Switched to Power-saver mode"
        ;;
esac
