#!/bin/zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source "${0:A:h}/../colors.zsh"

line="$(pmset -g batt | awk -F'\t' 'NR==2{print $2}')"
pct="${line%%%*}"
pct="${pct##* }"
state="$(print -r -- "$line" | awk -F'; ' '{print $2}')"
[[ "$pct" != <-> ]] && pct=0

icon=$'\U000f0079'
color="$MINT"
if [[ "$state" == "charging" ]]; then
  icon=$'\U000f0084'
  color="$PEACH"
elif (( pct <= 15 )); then
  icon=$'\U000f0083'
  color="$ROSE"
elif (( pct < 30 )); then
  icon=$'\U000f007c'
elif (( pct < 50 )); then
  icon=$'\U000f007e'
elif (( pct < 70 )); then
  icon=$'\U000f0080'
elif (( pct < 90 )); then
  icon=$'\U000f0082'
fi

sketchybar --set battery icon="$icon" icon.color="$color" label="${pct}%" label.color="$color"
