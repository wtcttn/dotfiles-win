#!/bin/bash
# Moralerspace HWJPDOC Font Installer for Arch Linux
# This script downloads and installs Moralerspace HWJPDOC font from GitHub
#
# Features:
# - Downloads font from official GitHub releases
# - Installs to user fonts directory (~/.local/share/fonts)
# - Updates font cache automatically
# - Validates installation
# - Force reinstall option to update all styles
#
# Usage: ./install-moralerspace-font.sh [install|uninstall|check|help] [--force]

set -e

# Options
FORCE_INSTALL=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Font configuration
FONT_URL="https://github.com/yuru7/moralerspace/releases/download/v2.0.0/MoralerspaceHWJPDOC_v2.0.0.zip"
FONT_NAME="Moralerspace HWJPDOC"
TEMP_DIR="/tmp/moralerspace-install"
FONT_DIR="$HOME/.local/share/fonts"

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
    
    local missing_deps=()
    
    # Check for required commands
    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl or wget")
    fi
    
    if ! command -v fc-cache &> /dev/null; then
        missing_deps+=("fontconfig")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_color "$RED" "Error: Missing dependencies: ${missing_deps[*]}"
        print_color "$YELLOW" "Install with: sudo pacman -S unzip curl fontconfig"
        return 1
    fi
    
    print_color "$GREEN" "✓ All dependencies are installed"
    return 0
}

download_font() {
    print_color "$BLUE" "Downloading Moralerspace HWJPDOC font from GitHub..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download font
    if command -v curl &> /dev/null; then
        curl -L -o moralerspace.zip "$FONT_URL" || {
            print_color "$RED" "Failed to download font with curl"
            return 1
        }
    elif command -v wget &> /dev/null; then
        wget -O moralerspace.zip "$FONT_URL" || {
            print_color "$RED" "Failed to download font with wget"
            return 1
        }
    fi
    
    print_color "$GREEN" "✓ Download completed"
    return 0
}

extract_font() {
    print_color "$BLUE" "Extracting font files..."
    
    cd "$TEMP_DIR"
    
    unzip -o moralerspace.zip || {
        print_color "$RED" "Failed to extract font files"
        return 1
    }
    
    # Count extracted TTF files
    local ttf_count=$(find . -type f -name "*.ttf" | wc -l)
    print_color "$GREEN" "✓ Extraction completed ($ttf_count TTF files found)"
    
    # Show directory structure for debugging
    print_color "$BLUE" "Extracted files:"
    find . -type f -name "*.ttf" | head -10 | while read -r file; do
        print_color "$CYAN" "  • $(basename "$file")"
    done
    if [ $ttf_count -gt 10 ]; then
        print_color "$CYAN" "  ... and $((ttf_count - 10)) more files"
    fi
    
    return 0
}

install_font() {
    print_header "Installing Moralerspace HWJPDOC Font"
    
    if [ "$FORCE_INSTALL" = true ]; then
        print_color "$YELLOW" "⚠ Force install mode: All fonts will be reinstalled"
        echo ""
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Download font
    if ! download_font; then
        cleanup
        return 1
    fi
    
    # Extract font
    if ! extract_font; then
        cleanup
        return 1
    fi
    
    # Create font directory if it doesn't exist
    print_color "$BLUE" "Creating font directory: $FONT_DIR"
    mkdir -p "$FONT_DIR"
    
    # Install fonts
    print_color "$BLUE" "Installing font files..."
    print_color "$BLUE" "Target directory: $FONT_DIR"
    local installed_count=0
    local skipped_count=0
    local total_found=0
    
    # Count total TTF files first
    total_found=$(find "$TEMP_DIR" -type f -name "*.ttf" | wc -l)
    print_color "$BLUE" "Found $total_found TTF files to process"
    echo ""
    
    # Temporarily disable exit on error for the loop
    set +e
    
    # Find all TTF files (recursively) - using a simpler approach
    find "$TEMP_DIR" -type f -name "*.ttf" | while read -r font_file; do
        font_basename=$(basename "$font_file")
        dest_path="$FONT_DIR/$font_basename"
        
        if [ -f "$dest_path" ] && [ "$FORCE_INSTALL" = false ]; then
            print_color "$YELLOW" "  ⊘ $font_basename (already installed, use --force to reinstall)"
            skipped_count=$((skipped_count + 1))
        else
            if [ -f "$dest_path" ]; then
                print_color "$BLUE" "  ↻ $font_basename (force reinstalling)"
            fi
            if cp -f "$font_file" "$dest_path" 2>/dev/null; then
                print_color "$GREEN" "  ✓ $font_basename"
                installed_count=$((installed_count + 1))
            else
                print_color "$RED" "  ✗ Failed to copy $font_basename"
            fi
        fi
    done
    
    # Re-enable exit on error
    set -e
    
    echo ""
    
    # Recount installed fonts for accurate reporting
    total_installed=$(find "$FONT_DIR" -type f -name "*Moralerspace*.ttf" 2>/dev/null | wc -l)
    print_color "$GREEN" "✓ Font installation completed! (Total: $total_installed Moralerspace fonts in $FONT_DIR)"
    
    # Update font cache
    print_color "$BLUE" "Updating font cache..."
    fc-cache -fv "$FONT_DIR" > /dev/null 2>&1 || {
        print_color "$YELLOW" "Warning: Failed to update font cache, but fonts are installed"
    }
    print_color "$GREEN" "✓ Font cache updated"
    
    # Cleanup
    cleanup
    
    # Verify installation
    print_color "$BLUE" "Verifying installation..."
    verify_installation
    
    print_color "$GREEN" ""
    print_color "$GREEN" "========================================"
    print_color "$GREEN" "Installation completed successfully! 🎉"
    print_color "$GREEN" "========================================"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Next steps:"
    print_color "$CYAN" "1. Restart your terminal or applications to use the new font"
    print_color "$CYAN" "2. Run './install-moralerspace-font.sh check' to see all installed styles"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Ghostty configuration examples:"
    print_color "$CYAN" "  font-family = Moralerspace Neon HWJPDOC       # Proportional width"
    print_color "$CYAN" "  font-family = Moralerspace Argon HWJPDOC      # Monospace"
    print_color "$CYAN" "  font-family = Moralerspace Krypton HWJPDOC    # Wider variant"
    print_color "$CYAN" "  font-family = Moralerspace Xenon HWJPDOC      # Bold variant"
    print_color "$CYAN" "  font-family = Moralerspace Radon HWJPDOC      # Compact variant"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Available font families:"
    fc-list | grep -i moralerspace | cut -d: -f2 | cut -d, -f1 | sort -u | sed 's/^/  • /'
    print_color "$BLUE" ""
    print_color "$BLUE" "Total styles installed: $(fc-list | grep -i moralerspace | wc -l)"
    
    return 0
}

uninstall_font() {
    print_header "Uninstalling Moralerspace HWJPDOC Font"
    
    print_color "$BLUE" "Searching for Moralerspace fonts..."
    
    local removed_count=0
    
    # Find and remove Moralerspace fonts
    while IFS= read -r -d '' font_file; do
        local font_basename=$(basename "$font_file")
        print_color "$YELLOW" "  Removing: $font_basename"
        rm "$font_file"
        ((removed_count++))
    done < <(find "$FONT_DIR" -type f -name "*Moralerspace*.ttf" -print0 2>/dev/null)
    
    if [ $removed_count -eq 0 ]; then
        print_color "$YELLOW" "No Moralerspace fonts found"
        return 0
    fi
    
    print_color "$GREEN" "✓ Removed $removed_count font file(s)"
    
    # Update font cache
    print_color "$BLUE" "Updating font cache..."
    fc-cache -fv "$FONT_DIR" > /dev/null 2>&1
    print_color "$GREEN" "✓ Font cache updated"
    
    print_color "$GREEN" ""
    print_color "$GREEN" "Uninstallation completed successfully!"
    
    return 0
}

verify_installation() {
    if fc-list | grep -qi moralerspace; then
        print_color "$GREEN" "✓ Moralerspace fonts are installed and available"
        return 0
    else
        print_color "$RED" "✗ Moralerspace fonts not found in system"
        return 1
    fi
}

check_installation() {
    print_header "Checking Moralerspace Font Installation"
    
    print_color "$BLUE" "Font directory: $FONT_DIR"
    
    if [ -d "$FONT_DIR" ]; then
        print_color "$GREEN" "✓ Font directory exists"
    else
        print_color "$YELLOW" "! Font directory does not exist"
    fi
    
    print_color "$BLUE" ""
    print_color "$BLUE" "Installed Moralerspace fonts:"
    
    if [ -d "$FONT_DIR" ]; then
        local font_count=$(find "$FONT_DIR" -type f -name "*Moralerspace*.ttf" 2>/dev/null | wc -l)
        if [ $font_count -gt 0 ]; then
            find "$FONT_DIR" -type f -name "*Moralerspace*.ttf" 2>/dev/null | while read -r font; do
                print_color "$GREEN" "  ✓ $(basename "$font")"
            done
            print_color "$BLUE" ""
            print_color "$GREEN" "Total: $font_count font file(s)"
        else
            print_color "$YELLOW" "  No Moralerspace fonts found"
        fi
    fi
    
    print_color "$BLUE" ""
    print_color "$BLUE" "Available Moralerspace font families and styles (from fc-list):"
    
    if fc-list | grep -qi moralerspace; then
        # Show detailed font information with styles
        fc-list : family style file | grep -i moralerspace | sort | while IFS=: read -r family style file; do
            # Clean up the strings
            family=$(echo "$family" | xargs)
            style=$(echo "$style" | xargs)
            local basename=$(basename "$file" | xargs)
            print_color "$GREEN" "  ✓ $family - $style"
            print_color "$CYAN" "    └─ $basename"
        done
        print_color "$GREEN" ""
        print_color "$GREEN" "✓ Moralerspace fonts are available in the system"
        
        # Show available font families
        print_color "$BLUE" ""
        print_color "$BLUE" "Font families for configuration:"
        fc-list | grep -i moralerspace | cut -d: -f2 | cut -d, -f1 | sort -u | while read -r family; do
            print_color "$CYAN" "  • font-family = $family"
        done
    else
        print_color "$YELLOW" "  No Moralerspace fonts found in system font cache"
        print_color "$YELLOW" ""
        print_color "$YELLOW" "Try running: fc-cache -fv"
    fi
    
    return 0
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_color "$BLUE" "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

show_help() {
    print_header "Moralerspace HWJPDOC Font Installer"
    echo ""
    print_color "$WHITE" "Usage: ./install-moralerspace-font.sh [install|uninstall|check|help] [--force]"
    echo ""
    print_color "$YELLOW" "Commands:"
    print_color "$WHITE" "  install   - Download and install Moralerspace HWJPDOC font"
    print_color "$WHITE" "  uninstall - Remove Moralerspace HWJPDOC font"
    print_color "$WHITE" "  check     - Check current installation status (shows all styles)"
    print_color "$WHITE" "  help      - Show this help message"
    echo ""
    print_color "$YELLOW" "Options:"
    print_color "$WHITE" "  --force   - Force reinstall all font files (even if already installed)"
    print_color "$CYAN" "              Use this if only Regular style is installed"
    echo ""
    print_color "$YELLOW" "Examples:"
    print_color "$CYAN" "  ./install-moralerspace-font.sh install"
    print_color "$CYAN" "  ./install-moralerspace-font.sh install --force   # Reinstall all styles"
    print_color "$CYAN" "  ./install-moralerspace-font.sh check             # See installed styles"
    echo ""
    print_color "$YELLOW" "Dependencies (auto-checked):"
    print_color "$CYAN" "  • unzip"
    print_color "$CYAN" "  • curl or wget"
    print_color "$CYAN" "  • fontconfig (fc-cache)"
    echo ""
    print_color "$YELLOW" "Install dependencies on Arch Linux:"
    print_color "$CYAN" "  sudo pacman -S unzip curl fontconfig"
    echo ""
    print_color "$YELLOW" "Font Details:"
    print_color "$WHITE" "  Name:    Moralerspace HWJPDOC"
    print_color "$WHITE" "  Version: v2.0.0"
    print_color "$WHITE" "  Variants: Neon, Argon, Krypton, Xenon, Radon (5 families)"
    print_color "$WHITE" "  Styles:   Regular, Bold, Italic, BoldItalic (per family)"
    print_color "$WHITE" "  Source:   https://github.com/yuru7/moralerspace"
    print_color "$WHITE" "  License:  SIL Open Font License 1.1"
    echo ""
    print_color "$YELLOW" "Installation Location:"
    print_color "$CYAN" "  $FONT_DIR"
    echo ""
}

# Trap cleanup on exit
trap cleanup EXIT INT TERM

# Parse options
COMMAND="${1:-install}"

# Check for --force flag in any position
for arg in "$@"; do
    if [ "$arg" = "--force" ] || [ "$arg" = "-f" ]; then
        FORCE_INSTALL=true
        print_color "$YELLOW" "Force install mode enabled - will reinstall all fonts"
        echo ""
    fi
done

# Main script logic
case "$COMMAND" in
    install)
        install_font
        ;;
    uninstall)
        uninstall_font
        ;;
    check)
        check_installation
        ;;
    help|--help|-h)
        show_help
        ;;
    --force|-f)
        # --force as first argument with no command, default to install
        install_font
        ;;
    *)
        print_color "$RED" "Unknown option: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac

exit 0

