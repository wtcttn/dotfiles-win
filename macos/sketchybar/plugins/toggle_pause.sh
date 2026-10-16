#!/bin/zsh
# AeroSpace の enable 状態は CLI から読めないので、切り替えた結果をバー用のフラグに書く。
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
aerospace enable toggle
file="$HOME/.cache/sketchybar/aerospace-enabled"
mkdir -p "${file:h}"
state="on"
[[ -f "$file" ]] && state="$(tr -d '[:space:]' < "$file")"
if [[ "$state" == "off" ]]; then
  print -r -- on > "$file"
else
  print -r -- off > "$file"
fi
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
sketchybar --trigger aerospace_pause || true
