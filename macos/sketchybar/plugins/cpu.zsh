#!/bin/zsh
source "${0:A:h}/../colors.zsh"

usage="$(top -l 2 -n 0 -s 1 | awk '/CPU usage/ { idle=$7 } END { gsub(/%/, "", idle); printf "%d", 100 - idle }')"
color="$TEXT"
(( usage > 85 )) && color="$ROSE"
sketchybar --set cpu label="${usage}%" label.color="$color"
