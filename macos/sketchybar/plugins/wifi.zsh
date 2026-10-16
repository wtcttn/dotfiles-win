#!/bin/zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source "${0:A:h}/../colors.zsh"

cache="$HOME/.cache/sketchybar"
mkdir -p "$cache"
signal_file="$cache/wifi-signal"

device="$(networksetup -listallhardwareports 2>/dev/null | awk 'BEGIN{p=0} /Wi-Fi|AirPort/{p=1} p && /Device/{print $2; exit}')"
[[ -z "$device" ]] && device="en0"

summary="$(ipconfig getsummary "$device" 2>/dev/null)"
active="$(print -r -- "$summary" | awk -F': ' '/LinkStatusActive/{print $2; exit}')"
helper="$HOME/Library/Application Support/SketchyBar/SketchyBar.app/Contents/MacOS/SketchyBar"
ssid=""
if [[ -x "$helper" ]]; then
  ssid="$("$helper" 2>/dev/null || true)"
fi
if [[ -z "$ssid" || "$ssid" == "<redacted>" ]]; then
  ssid="$(print -r -- "$summary" | awk -F': ' '/^[[:space:]]*SSID : /{print $2; exit}')"
fi

if [[ -z "$ssid" || "$active" == "FALSE" ]]; then
  sketchybar --set wifi \
    icon=$'\U000f092b' \
    icon.color="$MUTED" \
    label="オフ" \
    label.color="$MUTED"
  exit 0
fi

if [[ ! -s "$signal_file" || -n "$(find "$signal_file" -mmin +2 -print -quit 2>/dev/null)" ]]; then
  (
    rssi="$(system_profiler SPAirPortDataType 2>/dev/null | awk '/Signal \/ Noise/{gsub(/dBm/,"",$4); print $4; exit}')"
    [[ -n "$rssi" ]] && print -r -- "$rssi" > "$signal_file"
  ) &
  disown
fi

rssi="$(cat "$signal_file" 2>/dev/null)"
icon=$'\U000f05a9'
if [[ "$rssi" == -* || "$rssi" == [0-9]* ]]; then
  if (( rssi >= -50 )); then
    icon=$'\U000f0928'
  elif (( rssi >= -60 )); then
    icon=$'\U000f0925'
  elif (( rssi >= -70 )); then
    icon=$'\U000f0922'
  elif (( rssi >= -80 )); then
    icon=$'\U000f091f'
  else
    icon=$'\U000f092b'
  fi
fi

# 位置情報を許可していないと、macOS は SSID を "<redacted>" として返す。
ssid="${ssid//\"/}"
if [[ -z "$ssid" || "$ssid" == "<redacted>" ]]; then
  sketchybar --set wifi \
    icon="$icon" \
    icon.color="$SKY" \
    label="" \
    label.drawing=off
else
  sketchybar --set wifi \
    icon="$icon" \
    icon.color="$SKY" \
    label="$ssid" \
    label.drawing=on \
    label.color="$TEXT"
fi
