#!/bin/zsh
cache="$HOME/.cache/sketchybar/weather"
mkdir -p "${cache:h}"

if [[ ! -f "$cache" || -n "$(find "$cache" -mmin +30 -print -quit 2>/dev/null)" ]]; then
  text="$(curl -fsSL --max-time 4 'https://wttr.in/?format=%c+%t' 2>/dev/null || true)"
  text="${text//$'\n'/}"
  [[ -n "$text" ]] && print -rn -- "$text" > "$cache"
fi

if [[ -f "$cache" ]]; then
  sketchybar --set weather label="$(<"$cache")" drawing=on
else
  sketchybar --set weather drawing=off
fi
