#!/bin/bash
# Grok Bot のボックスに Obsidian のボルトのリンクとスキルを入れる。何度実行してもよい。
#   ./grokbot/install.sh install   リンク、スキル、Syncthing
#   ./grokbot/install.sh convert   cursor/skills のうち grokbot/skills に無いものだけ変換する
#   ./grokbot/install.sh skills    スキルだけ入れ直す

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DOTFILES_DIR/.." && pwd)"
VAULT_DIR="${VAULT_DIR:-/home/box/sync/obsidian-vault}"
NOTES_LINK="$HOME/notes"
WORKFLOWS_DIR="${WORKFLOWS_DIR:-/home/box/agent-data/workflows}"
SUPERVISE="$HOME/.local/bin/syncthing-supervise.sh"

# Cursor スキルを Grok Bot 用に写す。Mac のボルト行の下にボックスの行を足し、source に grok-bot を足す。
convert_skill() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  sed -E \
    -e 's#^- Mac: `~/notes(.*)`$#&\n- Grok Bot: `/home/box/sync/obsidian-vault\1`（`~/notes` はここへのリンク）#' \
    -e 's#`source` は `cursor`。#`source` は `cursor`。Grok Bot が書くときは `grok-bot`。#' \
    "$src" > "$dest"
  # SKILL.md 以外のファイル（sources.md など）はそのまま写す。
  (cd "$(dirname "$src")" && find . -type f ! -name SKILL.md -exec cp --parents {} "$(dirname "$dest")/" \;)
  if ! grep -q '/home/box/sync/obsidian-vault' "$dest"; then
    printf '\n## Grok Bot\n\nボックスのボルトは `/home/box/sync/obsidian-vault`（`~/notes` はここへのリンク）。Grok Bot が書くノートの `source` は `grok-bot`。\n' >> "$dest"
  fi
}

convert_missing() {
  local dir slug
  for dir in "$REPO_DIR"/cursor/skills/*/; do
    slug="$(basename "$dir")"
    [ -f "$dir/SKILL.md" ] || continue
    if [ -f "$DOTFILES_DIR/skills/$slug/SKILL.md" ]; then
      echo "変換済み: $slug"
    else
      convert_skill "$dir/SKILL.md" "$DOTFILES_DIR/skills/$slug/SKILL.md"
      echo "変換しました: $slug"
    fi
  done
}

ensure_notes_link() {
  if [ -L "$NOTES_LINK" ]; then
    [ "$(readlink "$NOTES_LINK")" = "$VAULT_DIR" ] && { echo "~/notes はリンク済み"; return; }
    echo "~/notes は別の場所を指しています: $(readlink "$NOTES_LINK")" >&2; return 1
  elif [ -e "$NOTES_LINK" ]; then
    echo "~/notes がリンクでないので触りません" >&2; return 1
  fi
  ln -s "$VAULT_DIR" "$NOTES_LINK"
  echo "~/notes -> $VAULT_DIR"
}

install_skills() {
  local dir slug
  mkdir -p "$WORKFLOWS_DIR"
  for dir in "$DOTFILES_DIR"/skills/*/; do
    slug="$(basename "$dir")"
    mkdir -p "$WORKFLOWS_DIR/$slug"
    cp -r "$dir". "$WORKFLOWS_DIR/$slug/"
    echo "スキル: $WORKFLOWS_DIR/$slug/SKILL.md"
  done
}

start_syncthing() {
  if [ -x "$SUPERVISE" ]; then
    if pgrep -x syncthing >/dev/null; then
      echo "Syncthing は動いています"
    else
      nohup "$SUPERVISE" >/dev/null 2>&1 &
      echo "Syncthing を起動しました"
    fi
  else
    echo "$SUPERVISE が無いので Syncthing は飛ばします"
  fi
}

case "${1:-install}" in
  install) convert_missing; ensure_notes_link; install_skills; start_syncthing ;;
  convert) convert_missing ;;
  skills) convert_missing; install_skills ;;
  *) echo "usage: $0 [install|convert|skills]" >&2; exit 1 ;;
esac
