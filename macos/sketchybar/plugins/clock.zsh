#!/bin/zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export LC_TIME=ja_JP.UTF-8
source "${0:A:h}/style.zsh"

label="$(date '+%-m/%-d (%a) %H:%M')"
sketchybar --set clock label="$label"

ensure_gradient || exit 0
icon_w="$(text_width "JetBrainsMono Nerd Font" 13 regular $'\U0000f186')"
label_w="$(text_width "Moralerspace Neon HWJPDOC" 12 bold "$label")"
# icon 左右 12+4、label 左右 2+12。CoreText より SketchyBar が 2px 広い。
width=$((12 + icon_w + 4 + 2 + label_w + 12 + 2))
apply_gradient clock "$width" 28 14 ffa8d8ff ffc9b6ff clock
