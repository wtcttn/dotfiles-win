# グラデーション画像を作って SketchyBar の背景に載せる。
# Windows の yume-bar と同じ 135 度。

STYLE_DIR="${${(%):-%x}:A:h}"
GRADIENT_SRC="${STYLE_DIR:h}/gradient.swift"
GRADIENT_BIN="${HOME}/.cache/sketchybar/bin/gradient"
GRADIENT_CACHE="${HOME}/.cache/sketchybar/gradients"

ensure_gradient() {
  if [[ -x "$GRADIENT_BIN" && "$GRADIENT_SRC" -ot "$GRADIENT_BIN" ]]; then
    return 0
  fi
  mkdir -p "${GRADIENT_BIN:h}" "$GRADIENT_CACHE"
  swiftc -O -o "$GRADIENT_BIN" "$GRADIENT_SRC"
}

text_width() {
  local font="$1" size="$2" weight="$3" text="$4"
  print -r -- "$text" | "$GRADIENT_BIN" measure "$font" "$size" "$weight"
}

# 背景いっぱいに 135 度グラデーションを敷く。幅は中身と同じにして、項目が伸びないようにする。
apply_gradient() {
  local item="$1" width="$2" height="$3" radius="$4" from="$5" to="$6" name="$7"
  (( width < 1 )) && width=1
  local out="$GRADIENT_CACHE/${name}-${width}x${height}.png"
  if [[ ! -f "$out" ]]; then
    mkdir -p "$GRADIENT_CACHE"
    "$GRADIENT_BIN" render "$width" "$height" "$radius" "$from" "$to" "$out" || return 1
  fi
  sketchybar --set "$item" \
    background.image.scale=0.5 \
    background.image="$out" \
    background.image.drawing=on \
    background.color=0x00000000
}

# ワークスペース島。文字幅は固定なので、バー読み込み時に一度敷く。
paint_spaces_bracket() {
  ensure_gradient || return 1
  local font="Moralerspace Neon HWJPDOC"
  local sparkle
  sparkle="$(text_width "$font" 12 regular "✦")"
  local width=$((10 + sparkle + 2 + 1))
  local labels=(main1 main2 main3 main4 main5 right6 right7 right8 left9)
  local i=0
  local label text
  for label in $labels; do
    text="$(text_width "$font" 12 regular "$label")"
    width=$((width + 8 + text + 8))
    i=$((i + 1))
    (( i < ${#labels} )) && width=$((width + 2))
  done
  apply_gradient spaces "$width" 28 14 e030223c e0221a28 island
}
