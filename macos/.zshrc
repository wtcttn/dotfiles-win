# wslc-dev の .zshrc を Mac 向けにしたもの。Oh My Zsh は ~/.local/share/oh-my-zsh。

if [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.local/share/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled

plugins=(
  aliases
  copyfile
  copypath
  aws
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'

source $ZSH/oh-my-zsh.sh

# 端末のタブ名。待機中はディレクトリ名、実行中はコマンド名。
ZSH_THEME_TERM_TAB_TITLE_IDLE='✦ %1~'
ZSH_THEME_TERM_TITLE_IDLE='✦ %1~'

export PATH="$PATH:$HOME/.local/bin"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export LANG=ja_JP.UTF-8
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"

alias vi='nvim'
alias vim='nvim'

if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
fi

# node と pnpm は proto。グローバルの node は 22.18.0。
# リポジトリの .node-version と packageManager で切り替わる。
# Ruby は rbenv。proto の Ruby は Intel Mac 向けのビルド済みが無い。
if [[ -d "$HOME/.proto" ]]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi
