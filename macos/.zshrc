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

if [[ -d "$HOME/.proto" ]]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi

# 旧 dotfiles の .zshrc にあった Mac のランタイム。
export PATH="$HOME/.nodebrew/current/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi
if [[ -d /usr/local/opt/libpq ]]; then
  export LDFLAGS="-L/usr/local/opt/libpq/lib"
  export CPPFLAGS="-I/usr/local/opt/libpq/include"
  export PATH="/usr/local/opt/libpq/bin:$PATH"
fi

if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi
