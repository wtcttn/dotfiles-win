#!/bin/bash
# Mac に Ghostty、Neovim、Powerlevel10k を入れ、このディレクトリへシンボリックリンクする。

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
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

export PATH="$HOME/.local/bin:$PATH"
if command -v nvim >/dev/null 2>&1; then
  echo "Neovim のプラグインを lock どおりに入れます"
  nvim --headless "+Lazy! restore" +qa
fi

echo "完了。Ghostty を開き直すと設定が反映されます。"
