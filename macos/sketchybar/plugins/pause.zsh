#!/bin/zsh
source "${0:A:h}/../colors.zsh"
source "${0:A:h}/style.zsh"
file="$HOME/.cache/sketchybar/aerospace-enabled"
state="on"
[[ -f "$file" ]] && state="$(tr -d '[:space:]' < "$file")"
if [[ "$state" == "off" ]]; then
  sketchybar --set pause drawing=on label="paused" \
    background.drawing=on \
    label.color="$PLUM" \
    label.font="$FONT_BOLD"
  if ensure_gradient; then
    text_w="$(text_width "Moralerspace Neon HWJPDOC" 12 bold "paused")"
    apply_gradient pause $((10 + text_w + 10)) 28 14 fff0b3 ffc9b0 chip
  fi
else
  sketchybar --set pause drawing=off
fi
