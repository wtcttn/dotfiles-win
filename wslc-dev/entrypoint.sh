#!/bin/bash
set -euo pipefail

CONFIG_HOME=/opt/wslc-dev/home
USER_NAME=kento
USER_HOME=/home/${USER_NAME}

link_config() {
  local src="$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    return
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] || [ ! -e "$dest" ]; then
    ln -sfn "$src" "$dest"
  fi
}

sync_ssh() {
  local src=/mnt/win-ssh
  local dst="${USER_HOME}/.ssh"
  local item base

  if [ ! -d "$src" ]; then
    return
  fi

  mkdir -p "$dst"
  for item in "$src"/*; do
    [ -f "$item" ] || continue
    base="$(basename "$item")"
    case "$base" in
      .* | *.swp) continue ;;
    esac
    cp -f "$item" "${dst}/${base}"
    case "$base" in
      *.pub | config | known_hosts | known_hosts.old)
        chmod 644 "${dst}/${base}"
        ;;
      *)
        chmod 600 "${dst}/${base}"
        ;;
    esac
  done
  chown -R "${USER_NAME}:${USER_NAME}" "$dst"
  chmod 700 "$dst"
}

if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$USER_HOME" /workspace
  if [ "$(stat -c '%u' "$USER_HOME")" != "1000" ]; then
    chown "${USER_NAME}:${USER_NAME}" "$USER_HOME"
  fi

  link_config "${CONFIG_HOME}/.zshenv" "${USER_HOME}/.zshenv"
  link_config "${CONFIG_HOME}/.zshrc" "${USER_HOME}/.zshrc"
  link_config "${CONFIG_HOME}/.p10k.zsh" "${USER_HOME}/.p10k.zsh"
  link_config "${CONFIG_HOME}/.gitconfig" "${USER_HOME}/.gitconfig"
  link_config "${CONFIG_HOME}/.config/nvim" "${USER_HOME}/.config/nvim"
  sync_ssh
  chown -h "${USER_NAME}:${USER_NAME}" \
    "${USER_HOME}/.zshenv" \
    "${USER_HOME}/.zshrc" \
    "${USER_HOME}/.p10k.zsh" \
    "${USER_HOME}/.gitconfig" \
    "${USER_HOME}/.config" \
    "${USER_HOME}/.config/nvim" 2>/dev/null || true

  exec runuser --preserve-environment -u "$USER_NAME" -- "$@"
fi

exec "$@"
