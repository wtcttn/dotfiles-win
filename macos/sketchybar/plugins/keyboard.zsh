#!/bin/zsh
# 日本語入力は「あ」、それ以外はレイアウト名。
label="$(defaults read "$HOME/Library/Preferences/com.apple.HIToolbox.plist" AppleSelectedInputSources 2>/dev/null | awk '
  /^[[:space:]]*"KeyboardLayout Name"/ {
    sub(/^.*"KeyboardLayout Name" *= */, "")
    gsub(/[";]/, "")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    name = $0
  }
  /^[[:space:]]*"Input Mode"/ {
    sub(/^.*"Input Mode" *= */, "")
    gsub(/[";]/, "")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    mode = $0
  }
  END {
    if (mode ~ /Japanese/) print "あ"
    else if (name != "") print name
    else print "?"
  }
')"
[[ -z "$label" ]] && label="?"
sketchybar --set keyboard label="$label"
