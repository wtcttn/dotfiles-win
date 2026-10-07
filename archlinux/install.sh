#!/bin/bash

# Dotfiles installer script
# This script creates symbolic links from the dotfiles directory to the home directory

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create symbolic link
create_symlink() {
  local source="$1"
  local target="$2"
  local name="$3"

  if [ -L "$target" ]; then
    echo -e "${YELLOW}Removing existing symlink: $target${NC}"
    rm "$target"
  elif [ -e "$target" ]; then
    echo -e "${YELLOW}Backing up existing file: $target -> $target.backup${NC}"
    mv "$target" "$target.backup"
  fi

  echo -e "${GREEN}Creating symlink: $name${NC}"
  ln -s "$source" "$target"
}

# Function to recursively install config directory
install_config_recursive() {
  local source_base="$1"
  local target_base="$2"
  local relative_path="$3"

  local source_dir="$source_base/$relative_path"
  local target_dir="$target_base/$relative_path"

  # Create target directory if it doesn't exist
  mkdir -p "$target_dir"

  # Process all items in the source directory
  for item in "$source_dir"/*; do
    [ -e "$item" ] || continue # Skip if glob doesn't match anything

    local item_name=$(basename "$item")
    local new_relative_path="$relative_path/$item_name"
    # Remove leading slash if present
    new_relative_path="${new_relative_path#/}"

    local source_item="$source_base/$new_relative_path"
    local target_item="$target_base/$new_relative_path"

    if [ -d "$item" ]; then
      # For directories, create symlink to the entire directory
      create_symlink "$source_item" "$target_item" ".config/$new_relative_path"
    elif [ -f "$item" ]; then
      # For files, create symlink
      create_symlink "$source_item" "$target_item" ".config/$new_relative_path"
    fi
  done
}

# Function to install Powerlevel10k
install_powerlevel10k() {
  local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  if [ -d "$P10K_DIR" ]; then
    echo -e "${YELLOW}Powerlevel10k already installed. Updating...${NC}"
    cd "$P10K_DIR" && git pull
  else
    echo -e "${GREEN}Installing Powerlevel10k...${NC}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  fi

  echo -e "${GREEN}Powerlevel10k installation completed!${NC}"
  echo -e "${YELLOW}Run 'p10k configure' to configure Powerlevel10k after restarting your shell${NC}"
}

# Function to install paru (AUR helper for Arch Linux)
install_paru() {
  # Check if running on Arch Linux
  if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}Not running on Arch Linux. Skipping paru installation.${NC}"
    return
  fi

  if command -v paru &>/dev/null; then
    echo -e "${YELLOW}paru is already installed. Skipping...${NC}"
    return
  fi

  echo -e "${GREEN}Installing paru (AUR helper)...${NC}"

  # Install dependencies
  sudo pacman -S --needed --noconfirm git base-devel

  # Clone and install paru
  local TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd "$HOME"
  rm -rf "$TEMP_DIR"

  echo -e "${GREEN}paru installation completed!${NC}"
  echo -e "${YELLOW}Note: You can use 'yay' as an alias for 'paru' (configured in .zshrc)${NC}"
}

# Function to install dotfiles
install_dotfiles() {
  echo -e "${GREEN}Installing dotfiles...${NC}"

  # Install Powerlevel10k theme
  if [ -d "$HOME/.oh-my-zsh" ]; then
    install_powerlevel10k
  else
    echo -e "${YELLOW}Oh My Zsh not found. Skipping Powerlevel10k installation.${NC}"
    echo -e "${YELLOW}Install Oh My Zsh first: https://ohmyz.sh/${NC}"
  fi

  # Create local bin directory
  if [ -d "$HOME_DIR/.local/bin" ]; then
    echo -e "${YELLOW}Local bin directory already exists. Skipping...${NC}"
  else
    mkdir -p "$HOME_DIR/.local/bin"
  fi

  # Install paru (AUR helper) if on Arch Linux
  install_paru

  echo ""
  echo -e "${GREEN}Installing dotfile symlinks...${NC}"

  # List of files to symlink (relative to dotfiles directory)
  files=(
    ".zshrc"
    ".zshenv"
    ".bashrc"
    ".gitconfig"
    ".vimrc"
    ".tmux.conf"
    ".gitignore_global"
    ".p10k.zsh"
    ".proto/.prototools"
  )

  for file in "${files[@]}"; do
    source_file="$DOTFILES_DIR/$file"
    target_file="$HOME_DIR/$file"

    if [ -f "$source_file" ]; then
      create_symlink "$source_file" "$target_file" "$file"
    elif [ -d "$source_file" ]; then
      create_symlink "$source_file" "$target_file" "$file"
    else
      echo -e "${YELLOW}File not found: $file (skipping)${NC}"
    fi
  done

  # Create directories for config files
  mkdir -p "$HOME_DIR/.config"

  # Install config files recursively
  if [ -d "$DOTFILES_DIR/.config" ]; then
    echo ""
    echo -e "${GREEN}Installing .config files...${NC}"
    install_config_recursive "$DOTFILES_DIR/.config" "$HOME_DIR/.config" ""
  fi

  echo -e "${GREEN}Dotfiles installation completed!${NC}"
}

# Function to uninstall dotfiles
uninstall_dotfiles() {
  echo -e "${YELLOW}Uninstalling dotfiles...${NC}"

  files=(
    ".zshrc"
    ".bashrc"
    ".gitconfig"
    ".vimrc"
    ".tmux.conf"
    ".gitignore_global"
    ".p10k.zsh"
  )

  for file in "${files[@]}"; do
    target_file="$HOME_DIR/$file"
    if [ -L "$target_file" ]; then
      echo -e "${GREEN}Removing symlink: $file${NC}"
      rm "$target_file"
    fi
  done

  echo -e "${GREEN}Dotfiles uninstallation completed!${NC}"
}

# Main script
case "${1:-install}" in
"install")
  install_dotfiles
  ;;
"uninstall")
  uninstall_dotfiles
  ;;
"help" | "-h" | "--help")
  echo "Usage: $0 [install|uninstall|help]"
  echo "  install   - Install dotfiles (default)"
  echo "  uninstall - Remove dotfile symlinks"
  echo "  help      - Show this help message"
  ;;
*)
  echo -e "${RED}Unknown option: $1${NC}"
  echo "Use '$0 help' for usage information"
  exit 1
  ;;
esac
