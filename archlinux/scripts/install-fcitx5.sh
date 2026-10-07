#!/bin/bash
# Fcitx5 Japanese IME Installer for Arch Linux
# WSLg上のGhosttyで日本語入力を有効化するスクリプト
#
# Features:
# - Fcitx5とMozcのインストール
# - 設定ファイルの配置
# - 環境変数の設定確認
#
# Usage: ./install-fcitx5.sh [install|check|help]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Functions
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    print_color "$CYAN" "===================================="
    print_color "$CYAN" "$1"
    print_color "$CYAN" "===================================="
}

check_dependencies() {
    print_color "$BLUE" "Checking dependencies..."
    
    if ! command -v paru > /dev/null 2>&1 && ! command -v yay > /dev/null 2>&1; then
        print_color "$RED" "Error: paru or yay is required"
        print_color "$YELLOW" "Install paru: https://github.com/Morganamilo/paru"
        return 1
    fi
    
    local aur_helper="paru"
    if ! command -v paru > /dev/null 2>&1; then
        aur_helper="yay"
    fi
    
    print_color "$GREEN" "✓ AUR helper found: $aur_helper"
    echo "$aur_helper"
}

install_fcitx5() {
    print_header "Installing Fcitx5 Japanese IME"
    
    local aur_helper=$(check_dependencies)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_color "$BLUE" "Installing Fcitx5 and Mozc..."
    print_color "$YELLOW" "This will install:"
    print_color "$CYAN" "  • fcitx5"
    print_color "$CYAN" "  • fcitx5-mozc (Japanese input method)"
    print_color "$CYAN" "  • fcitx5-configtool (Configuration tool)"
    print_color "$CYAN" "  • fcitx5-gtk (GTK integration)"
    echo ""
    
    # Install packages
    sudo pacman -S --needed --noconfirm \
        fcitx5 \
        fcitx5-mozc \
        fcitx5-configtool \
        fcitx5-gtk \
        fcitx5-qt \
        fcitx5-configtool || {
        print_color "$RED" "Failed to install Fcitx5 packages"
        return 1
    }
    
    print_color "$GREEN" "✓ Fcitx5 installed successfully"
    
    # Setup configuration directory
    print_color "$BLUE" "Setting up configuration directory (symbolic link)..."
    
    local config_dir="$HOME/.config/fcitx5"
    local dotfiles_fcitx5="$HOME/dotfiles/archlinux/.config/fcitx5"
    
    # Check if dotfiles fcitx5 directory exists
    if [ ! -d "$dotfiles_fcitx5" ]; then
        print_color "$RED" "Error: $dotfiles_fcitx5 directory not found"
        return 1
    fi
    
    # Remove existing directory/link
    if [ -L "$config_dir" ]; then
        print_color "$BLUE" "  Removing existing symlink: $config_dir"
        rm -f "$config_dir"
    elif [ -d "$config_dir" ]; then
        print_color "$YELLOW" "  Backing up existing directory: $config_dir -> $config_dir.backup"
        mv "$config_dir" "$config_dir.backup"
    fi
    
    # Create symbolic link to the entire fcitx5 directory
    ln -sf "$dotfiles_fcitx5" "$config_dir"
    print_color "$GREEN" "  ✓ Linked ~/.config/fcitx5 → $dotfiles_fcitx5"
    
    # Setup systemd user service
    print_color "$BLUE" "Setting up systemd user service..."
    
    local systemd_dir="$HOME/.config/systemd/user"
    local service_file="fcitx5.service"
    local dotfiles_service="$HOME/dotfiles/archlinux/.config/systemd/user/$service_file"
    
    # Check if dotfiles systemd service exists
    if [ -f "$dotfiles_service" ]; then
        mkdir -p "$systemd_dir"
        
        # Remove existing service file/link
        rm -f "$systemd_dir/$service_file"
        
        # Create symbolic link to systemd service
        ln -sf "$dotfiles_service" "$systemd_dir/$service_file"
        print_color "$GREEN" "  ✓ Linked systemd service"
        
        # Reload systemd daemon
        systemctl --user daemon-reload
        print_color "$GREEN" "  ✓ Reloaded systemd daemon"
        
        # Enable the service (auto-start on WSL login)
        systemctl --user enable fcitx5.service
        print_color "$GREEN" "  ✓ Enabled fcitx5.service (auto-start on login)"
        
        # Try to start the service if in GUI environment
        if [ -n "$DISPLAY" ]; then
            if ! systemctl --user is-active --quiet fcitx5.service; then
                systemctl --user start fcitx5.service
                print_color "$GREEN" "  ✓ Started fcitx5.service"
            else
                print_color "$YELLOW" "  ⚠ fcitx5.service already running"
            fi
        else
            print_color "$CYAN" "  ℹ Service enabled (will start automatically when GUI session starts)"
        fi
    else
        print_color "$YELLOW" "  ⚠ Systemd service file not found: $dotfiles_service"
    fi
    
    print_color "$GREEN" "✓ Configuration completed (changes in dotfiles will be reflected automatically)"
    
    print_color "$GREEN" ""
    print_color "$GREEN" "========================================"
    print_color "$GREEN" "Installation completed successfully! 🎉"
    print_color "$GREEN" "========================================"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Next steps:"
    print_color "$CYAN" "1. Restart your shell to load environment variables:"
    print_color "$CYAN" "   source ~/.zshrc"
    print_color "$CYAN" "2. Start Ghostty - Fcitx5 will auto-start via systemd"
    print_color "$CYAN" "3. Press Ctrl+Space to switch to Japanese input"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Systemd service management:"
    print_color "$CYAN" "  • Check status:  systemctl --user status fcitx5"
    print_color "$CYAN" "  • Stop service:   systemctl --user stop fcitx5"
    print_color "$CYAN" "  • Restart:        systemctl --user restart fcitx5"
    print_color "$CYAN" "  • View logs:      journalctl --user -u fcitx5 -f"
    print_color "$CYAN" "  • Disable:        systemctl --user disable fcitx5"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Usage:"
    print_color "$CYAN" "  • Ctrl+Space: Toggle Japanese/English input"
    print_color "$CYAN" "  • Shift+Space: Toggle Hiragana/Half-width"
    print_color "$CYAN" "  • fcitx5-configtool: Configure IME settings (GUI)"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Important:"
    print_color "$CYAN" "  • Fcitx5 runs as systemd user service (auto-start on WSL login)"
    print_color "$CYAN" "  • Only starts when DISPLAY is set (GUI environment)"
    print_color "$CYAN" "  • CLI environment (Windows Terminal) is not affected"
    
    return 0
}

check_installation() {
    print_header "Checking Fcitx5 Installation"
    
    local all_ok=true
    
    # Check if Fcitx5 is installed
    if command -v fcitx5 > /dev/null 2>&1; then
        print_color "$GREEN" "✓ Fcitx5 is installed"
        print_color "$CYAN" "  Version: $(fcitx5 --version 2>&1 | head -1)"
    else
        print_color "$RED" "✗ Fcitx5 is not installed"
        all_ok=false
    fi
    
    # Check if Mozc is installed
    if pacman -Qi fcitx5-mozc > /dev/null 2>&1; then
        print_color "$GREEN" "✓ fcitx5-mozc is installed"
    else
        print_color "$RED" "✗ fcitx5-mozc is not installed"
        all_ok=false
    fi
    
    # Check environment variables
    echo ""
    print_color "$BLUE" "Environment variables (in current shell):"
    print_color "$CYAN" "Note: These are set by .xprofile in GUI sessions"
    
    if [ -n "$GTK_IM_MODULE" ]; then
        if [ "$GTK_IM_MODULE" = "fcitx" ]; then
            print_color "$GREEN" "  ✓ GTK_IM_MODULE=$GTK_IM_MODULE"
        else
            print_color "$YELLOW" "  ⚠ GTK_IM_MODULE=$GTK_IM_MODULE (should be 'fcitx')"
        fi
    else
        print_color "$YELLOW" "  ⚠ GTK_IM_MODULE is not set"
        print_color "$CYAN" "    (Normal in CLI environment - set by .xprofile in GUI)"
    fi
    
    if [ -n "$XMODIFIERS" ]; then
        if [ "$XMODIFIERS" = "@im=fcitx" ]; then
            print_color "$GREEN" "  ✓ XMODIFIERS=$XMODIFIERS"
        else
            print_color "$YELLOW" "  ⚠ XMODIFIERS=$XMODIFIERS (should be '@im=fcitx')"
        fi
    else
        print_color "$YELLOW" "  ⚠ XMODIFIERS is not set"
        print_color "$CYAN" "    (Normal in CLI environment - set by .xprofile in GUI)"
    fi
    
    # Check systemd service status
    echo ""
    print_color "$BLUE" "Systemd service status:"
    if systemctl --user is-enabled --quiet fcitx5.service 2>/dev/null; then
        print_color "$GREEN" "  ✓ fcitx5.service is enabled"
        
        if systemctl --user is-active --quiet fcitx5.service; then
            print_color "$GREEN" "  ✓ fcitx5.service is active (running)"
            if pgrep -x fcitx5 > /dev/null; then
                print_color "$GREEN" "  ✓ Fcitx5 process is running (PID: $(pgrep -x fcitx5))"
            fi
        else
            print_color "$YELLOW" "  ⚠ fcitx5.service is not active"
            print_color "$CYAN" "    Start with: systemctl --user start fcitx5"
        fi
    else
        print_color "$YELLOW" "  ⚠ fcitx5.service is not enabled"
        print_color "$CYAN" "    Enable with: systemctl --user enable --now fcitx5"
    fi
    
    # Check systemd service file
    if [ -L "$HOME/.config/systemd/user/fcitx5.service" ]; then
        local target=$(readlink "$HOME/.config/systemd/user/fcitx5.service")
        print_color "$GREEN" "  ✓ Service file linked: $target"
    elif [ -f "$HOME/.config/systemd/user/fcitx5.service" ]; then
        print_color "$YELLOW" "  ⚠ Service file exists (not a symlink)"
    else
        print_color "$RED" "  ✗ Service file not found"
    fi
    
    # Check configuration directory
    echo ""
    print_color "$BLUE" "Configuration directory:"
    
    if [ -L "$HOME/.config/fcitx5" ]; then
        local target=$(readlink "$HOME/.config/fcitx5")
        print_color "$GREEN" "  ✓ ~/.config/fcitx5 → $target"
        
        # Check if target directory exists and contains config files
        if [ -d "$target" ]; then
            if [ -f "$target/config" ]; then
                print_color "$GREEN" "    ✓ config file exists in target"
            else
                print_color "$YELLOW" "    ⚠ config file not found in target"
            fi
            if [ -f "$target/profile" ]; then
                print_color "$GREEN" "    ✓ profile file exists in target"
            else
                print_color "$YELLOW" "    ⚠ profile file not found in target"
            fi
        else
            print_color "$RED" "    ✗ Target directory does not exist!"
        fi
    elif [ -d "$HOME/.config/fcitx5" ]; then
        print_color "$YELLOW" "  ⚠ ~/.config/fcitx5 exists (not a symlink)"
        print_color "$CYAN" "    Run 'install' to convert to symlink"
    else
        print_color "$YELLOW" "  ⚠ ~/.config/fcitx5 not found"
    fi
    
    if [ "$all_ok" = true ]; then
        echo ""
        print_color "$GREEN" "✓ All checks passed!"
    else
        echo ""
        print_color "$YELLOW" "⚠ Some checks failed. Run 'install' to fix."
    fi
    
    return 0
}

show_help() {
    print_header "Fcitx5 Japanese IME Installer"
    echo ""
    print_color "$WHITE" "Usage: ./install-fcitx5.sh [install|check|help]"
    echo ""
    print_color "$YELLOW" "Commands:"
    print_color "$WHITE" "  install   - Install Fcitx5 and Mozc with configuration"
    print_color "$WHITE" "  check     - Check current installation status"
    print_color "$WHITE" "  help      - Show this help message"
    echo ""
    print_color "$YELLOW" "What this installs:"
    print_color "$CYAN" "  • fcitx5 - Modern Input Method Framework"
    print_color "$CYAN" "  • fcitx5-mozc - Japanese input method (Google Japanese Input)"
    print_color "$CYAN" "  • fcitx5-configtool - Configuration GUI tool"
    print_color "$CYAN" "  • fcitx5-gtk - GTK integration (for Ghostty)"
    print_color "$CYAN" "  • fcitx5-qt - Qt integration"
    echo ""
    print_color "$YELLOW" "Key Bindings:"
    print_color "$CYAN" "  • Ctrl+Space: Toggle Japanese/English input"
    print_color "$CYAN" "  • Shift+Space: Toggle Hiragana/Half-width"
    echo ""
    print_color "$YELLOW" "After installation:"
    print_color "$CYAN" "  1. Restart shell: source ~/.zshrc"
    print_color "$CYAN" "  2. Start Ghostty - Fcitx5 runs as systemd service"
    print_color "$CYAN" "  3. Use Ctrl+Space to toggle Japanese input"
    echo ""
    print_color "$YELLOW" "Service management:"
    print_color "$CYAN" "  • systemctl --user status fcitx5   # Check status"
    print_color "$CYAN" "  • systemctl --user restart fcitx5  # Restart service"
    print_color "$CYAN" "  • journalctl --user -u fcitx5 -f   # View logs"
    echo ""
    print_color "$YELLOW" "Note:"
    print_color "$CYAN" "  • ~/.config/fcitx5 directory is symlinked to ~/dotfiles/archlinux/.config/fcitx5"
    print_color "$CYAN" "  • Fcitx5 managed by systemd (auto-start, auto-restart)"
    print_color "$CYAN" "  • IME environment variables set in .zshrc (GUI only)"
    print_color "$CYAN" "  • Changes to dotfiles will be reflected automatically"
    print_color "$CYAN" "  • CLI environment (Windows Terminal) is not affected"
    echo ""
}

# Main script logic
case "${1:-help}" in
    install)
        install_fcitx5
        ;;
    check)
        check_installation
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_color "$RED" "Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

exit 0

