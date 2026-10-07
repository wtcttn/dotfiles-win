# Arch 側の .zshrc と同じ構成。コンテナに無いコマンドは読み込まない。

if [[ -o interactive ]] && command -v screenfetch >/dev/null 2>&1; then
  screenfetch
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=/usr/share/oh-my-zsh
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled

plugins=(
  aliases
  archlinux
  copyfile
  copypath
  aws
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'

source $ZSH/oh-my-zsh.sh

export PATH="$PATH:$HOME/.local/bin"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export TZ="Asia/Tokyo"
export LANG=ja_JP.UTF-8

alias yay='paru'
alias vi='nvim'
alias vim='nvim'

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

export PROTO_HOME="$HOME/.proto"
export PROTO_LOOKUP_DIR=/usr/bin
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"

[ -f ~/.zshrc.local ] && source ~/.zshrc.local
