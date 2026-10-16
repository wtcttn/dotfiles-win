#!/bin/zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source "${0:A:h}/../colors.zsh"

if [[ "$1" == "toggle" ]]; then
  osascript -e 'set volume output muted not (output muted of (get volume settings))' >/dev/null
fi

settings="$(osascript -e 'get volume settings' 2>/dev/null)"
vol="$(print -r -- "$settings" | sed -n 's/.*output volume:\([0-9]*\).*/\1/p')"
muted="$(print -r -- "$settings" | sed -n 's/.*output muted:\([a-z]*\).*/\1/p')"
[[ -z "$vol" ]] && vol=0

if [[ "$muted" == "true" || "$vol" == "0" ]]; then
  sketchybar --set volume icon=$'\U000f075f' icon.color="$MUTED" label="消" label.color="$MUTED"
  exit 0
fi

icon=$'\U000f057e'
if (( vol < 30 )); then
  icon=$'\U000f057f'
elif (( vol < 70 )); then
  icon=$'\U000f0580'
fi

sketchybar --set volume icon="$icon" icon.color="$PINK" label="${vol}%" label.color="$TEXT"
