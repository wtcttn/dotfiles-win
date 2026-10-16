#!/bin/zsh
# ワークスペース、ウィンドウ名、分割方向をまとめて描き直す。
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source "${0:A:h}/../colors.zsh"
source "${0:A:h}/style.zsh"

typeset -A LABELS
LABELS=(
  1 main1
  2 main2
  3 main3
  4 main4
  5 main5
  6 right6
  7 right7
  8 right8
  9 left9
)

if ! command -v aerospace >/dev/null 2>&1; then
  exit 0
fi

can_gradient=0
if ensure_gradient; then
  can_gradient=1
fi

focused="$(aerospace list-workspaces --focused --format '%{workspace}' 2>/dev/null | head -1)"
focused="${focused%% *}"
visible="$(aerospace list-workspaces --monitor all --visible --format '%{workspace}' 2>/dev/null)"
occupied="$(aerospace list-windows --all --format '%{workspace}' 2>/dev/null)"

typeset -a shown_labels
shown_labels=()
for sid in 1 2 3 4 5 6 7 8 9; do
  label="${LABELS[$sid]}"
  # 窓の無いタブは隠す。今いる場所だけは空でも残す。
  if ! print -r -- "$occupied" | grep -qx "$sid" && [[ "$sid" != "$focused" ]]; then
    sketchybar --set "space.$sid" drawing=off
    continue
  fi
  shown_labels+=("$label")
  sketchybar --set "space.$sid" drawing=on
  if [[ "$sid" == "$focused" ]]; then
    sketchybar --set "space.$sid" \
      label.color="$PLUM" \
      label.font="$FONT_BOLD" \
      background.drawing=on \
      background.height=22 \
      background.corner_radius=11
    if (( can_gradient )); then
      text_w="$(text_width "Moralerspace Neon HWJPDOC" 12 bold "$label")"
      pill_w=$((8 + text_w + 8))
      apply_gradient "space.$sid" "$pill_w" 22 11 f5a8d6 c9b6ff "focus"
    else
      sketchybar --set "space.$sid" background.color="$PINK"
    fi
  elif print -r -- "$visible" | grep -qx "$sid"; then
    sketchybar --set "space.$sid" \
      label.color="$LAVENDER" \
      label.font="$FONT" \
      background.drawing=on \
      background.image.drawing=off \
      background.color="$DISPLAYED" \
      background.height=22 \
      background.corner_radius=11
  else
    sketchybar --set "space.$sid" \
      label.color="$MUTED" \
      label.font="$FONT" \
      background.drawing=off \
      background.image.drawing=off
  fi
done

if (( can_gradient )); then
  paint_spaces_bracket "${shown_labels[@]}" || true
fi

title="$(aerospace list-windows --focused --format '%{window-title}' 2>/dev/null | head -1)"
if [[ -n "$title" ]]; then
  sketchybar --set title drawing=on label="$title" icon.drawing=on
else
  sketchybar --set title drawing=off
fi

layout="$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null | head -1)"
case "$layout" in
  v_tiles) icon=$'\U000f04e2' ;;
  *) icon=$'\U000f04e1' ;;
esac
sketchybar --set layout icon="$icon"
