#!/bin/bash
# AeroSpace 起動時にバーと枠を出す。既に居れば二度起動しない。
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-/usr/bin:/bin}"

mkdir -p "$HOME/.cache/sketchybar"
if [[ ! -f "$HOME/.cache/sketchybar/aerospace-enabled" ]]; then
  echo on > "$HOME/.cache/sketchybar/aerospace-enabled"
fi

if ! pgrep -x sketchybar >/dev/null 2>&1; then
  nohup sketchybar >/dev/null 2>&1 &
  disown || true
  sleep 0.4
fi

if ! pgrep -x borders >/dev/null 2>&1; then
  nohup "$HOME/.config/borders/bordersrc" >/dev/null 2>&1 &
  disown || true
fi

sketchybar --trigger aerospace_focus_change || true
sketchybar --trigger aerospace_mode_change || true
sketchybar --trigger aerospace_pause || true
