#!/bin/zsh
source "${0:A:h}/../colors.zsh"

page="$(pagesize)"
total="$(sysctl -n hw.memsize)"
used="$(vm_stat | awk -v page="$page" '
  /Pages active:/ { gsub(/\./, "", $3); active = $3 }
  /Pages wired down:/ { gsub(/\./, "", $4); wired = $4 }
  /Pages occupied by compressor:/ { gsub(/\./, "", $5); comp = $5 }
  END { print (active + wired + comp) * page }
')"
usage=$(( used * 100 / total ))
color="$TEXT"
(( usage > 85 )) && color="$ROSE"
sketchybar --set memory label="${usage}%" label.color="$color"
