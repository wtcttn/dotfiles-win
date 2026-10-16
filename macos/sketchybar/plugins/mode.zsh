#!/bin/zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source "${0:A:h}/../colors.zsh"
source "${0:A:h}/style.zsh"

mode="$(aerospace list-modes --current 2>/dev/null | head -1)"
if [[ -z "$mode" || "$mode" == "main" ]]; then
  sketchybar --set mode drawing=off
else
  sketchybar --set mode drawing=on label="$mode" \
    background.drawing=on \
    label.color="$PLUM" \
    label.font="$FONT_BOLD"
  if ensure_gradient; then
    text_w="$(text_width "Moralerspace Neon HWJPDOC" 12 bold "$mode")"
    apply_gradient mode $((10 + text_w + 10)) 28 14 fff0b3 ffc9b0 chip
  fi
fi
