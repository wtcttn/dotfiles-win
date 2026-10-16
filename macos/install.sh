#!/bin/bash
# Mac に Ghostty、Neovim、Powerlevel10k、AeroSpace、SketchyBar を入れ、このディレクトリへシンボリックリンクする。

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_URL="https://github.com/yuru7/moralerspace/releases/download/v2.0.0/MoralerspaceHWJPDOC_v2.0.0.zip"
FONT_DIR="$HOME/Library/Fonts"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew がありません" >&2
  exit 1
fi

echo "パッケージを入れます"
export HOMEBREW_NO_AUTO_UPDATE=1
brew bundle --file="$DOTFILES_DIR/Brewfile"

if brew info neovim 2>/dev/null | grep -q '(bottled)'; then
  brew install neovim
else
  echo "Neovim の bottle が無いので、公式の macOS バイナリを ~/.local に入れます"
  case "$(uname -m)" in
    x86_64) nvim_arch="x86_64" ;;
    arm64) nvim_arch="arm64" ;;
    *)
      echo "未対応のアーキテクチャです: $(uname -m)" >&2
      exit 1
      ;;
  esac
  nvim_version="v0.12.6"
  nvim_name="nvim-macos-${nvim_arch}"
  if "$HOME/.local/bin/nvim" --version 2>/dev/null | head -n 1 | grep -q "NVIM ${nvim_version}"; then
    echo "Neovim ${nvim_version} は入っています"
  else
    nvim_tmp="$(mktemp -d)"
    curl -fsSL -o "$nvim_tmp/nvim.tar.gz" \
      "https://github.com/neovim/neovim/releases/download/${nvim_version}/${nvim_name}.tar.gz"
    tar -xzf "$nvim_tmp/nvim.tar.gz" -C "$nvim_tmp"
    mkdir -p "$HOME/.local"
    cp -R "$nvim_tmp/$nvim_name/." "$HOME/.local/"
    rm -rf "$nvim_tmp"
  fi
fi

if brew info chafa 2>/dev/null | grep -q '(bottled)'; then
  brew install chafa
else
  echo "chafa の bottle が無いので入れません。起動画面の絵だけ出ません。"
fi

if ! compgen -G "$FONT_DIR/MoralerspaceNeon*HWJPDOC*.ttf" >/dev/null 2>&1; then
  echo "Moralerspace Neon HWJPDOC を入れます"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/font.zip" "$FONT_URL"
  unzip -q "$tmp/font.zip" -d "$tmp/font"
  mkdir -p "$FONT_DIR"
  find "$tmp/font" -iname 'MoralerspaceNeon*HWJPDOC*.ttf' -exec cp {} "$FONT_DIR/" \;
  trap - EXIT
  rm -rf "$tmp"
else
  echo "フォントは入っています"
fi

if [[ ! -x "$HOME/.proto/bin/proto" ]]; then
  echo "proto を入れます"
  proto_tmp="$(mktemp)"
  curl -fsSL -o "$proto_tmp" https://moonrepo.dev/install/proto.sh
  PROTO_HOME="$HOME/.proto" bash "$proto_tmp" --yes --no-profile
  rm -f "$proto_tmp"
fi

link_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    echo "既存の $target を $target.backup に退避します"
    rm -rf "$target.backup"
    mv "$target" "$target.backup"
  fi
  ln -s "$source" "$target"
  echo "link: $target -> $source"
}

link_dir() { link_path "$@"; }
link_file() { link_path "$@"; }

if [[ ! -d "$HOME/.local/share/oh-my-zsh/.git" ]]; then
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.local/share/oh-my-zsh"
fi
zsh_custom="$HOME/.local/share/oh-my-zsh/custom"
mkdir -p "$zsh_custom/themes" "$zsh_custom/plugins"
[[ -d "$zsh_custom/themes/powerlevel10k/.git" ]] || git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
[[ -d "$zsh_custom/plugins/zsh-autosuggestions/.git" ]] || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
[[ -d "$zsh_custom/plugins/zsh-syntax-highlighting/.git" ]] || git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"

if [[ ! -x "$HOME/.local/bin/fastfetch" ]]; then
  echo "fastfetch の公式バイナリを ~/.local に入れます"
  ff_tmp="$(mktemp -d)"
  ff_tag="$(gh release view --repo fastfetch-cli/fastfetch --json tagName --jq .tagName)"
  curl -fsSL -o "$ff_tmp/fastfetch.zip" \
    "https://github.com/fastfetch-cli/fastfetch/releases/download/${ff_tag}/fastfetch-macos-universal.zip"
  unzip -q "$ff_tmp/fastfetch.zip" -d "$ff_tmp"
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$(find "$ff_tmp" -type f -name fastfetch | head -1)" "$HOME/.local/bin/fastfetch"
  rm -rf "$ff_tmp"
fi

link_dir "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
link_dir "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_dir "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"
link_dir "$DOTFILES_DIR/aerospace" "$HOME/.config/aerospace"
link_dir "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
link_dir "$DOTFILES_DIR/borders" "$HOME/.config/borders"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

chmod +x \
  "$DOTFILES_DIR/aerospace/start-status.sh" \
  "$DOTFILES_DIR/borders/bordersrc" \
  "$DOTFILES_DIR/sketchybar/sketchybarrc" \
  "$DOTFILES_DIR/sketchybar/plugins/"*

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# borders の brew service は色を渡さない。ログイン時に bordersrc を起動する。
plist="$HOME/Library/LaunchAgents/com.kento.borders.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.kento.borders</string>
  <key>ProgramArguments</key>
  <array>
    <string>$HOME/.config/borders/bordersrc</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProcessType</key>
  <string>Interactive</string>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)/com.kento.borders" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"

mkdir -p "$HOME/.cache/sketchybar/bin"
swiftc -O -o "$HOME/.cache/sketchybar/bin/gradient" "$DOTFILES_DIR/sketchybar/gradient.swift" || true

# Wi-Fi 名は位置情報の許可が要る。SketchyBar という名前の小さなアプリで読む。
wifi_app="$HOME/Library/Application Support/SketchyBar/SketchyBar.app"
if [[ ! -x "$wifi_app/Contents/MacOS/SketchyBar" ]]; then
  mkdir -p "$wifi_app/Contents/MacOS"
  cp "$DOTFILES_DIR/sketchybar/wifissid/Info.plist" "$wifi_app/Contents/Info.plist"
  swiftc -O -framework AppKit -framework CoreLocation -framework CoreWLAN \
    -o "$wifi_app/Contents/MacOS/SketchyBar" \
    "$DOTFILES_DIR/sketchybar/wifissid/main.swift" || true
  codesign --force --deep --sign - "$wifi_app" || true
fi

if pgrep -x sketchybar >/dev/null 2>&1; then
  sketchybar --reload
else
  brew services start sketchybar
fi

# 標準メニューバーは常に隠す。ポインタを上端に寄せるとアプリメニューが出る。
osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true' >/dev/null 2>&1 || true

export PATH="$HOME/.local/bin:$PATH"
if command -v nvim >/dev/null 2>&1; then
  echo "Neovim のプラグインを lock どおりに入れます"
  nvim --headless "+Lazy! restore" +qa
fi

open -a AeroSpace

echo "完了。Ghostty を開き直すと設定が反映されます。"
echo "AeroSpace の初回は、システム設定のアクセシビリティで許可してください。許可するまでタイル配置は始まりません。"
