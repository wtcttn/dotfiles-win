# PowerShell Profile Installer Script
# This script manages PowerShell profile installation from WSL environment
#
# Features:
# - Installs PowerShell profile (Microsoft.PowerShell_profile.ps1)
# - Auto-installs Terminal-Icons and posh-git modules
# - Auto-installs Moralerspace HWJPDOC font (Japanese programming font)
# - Installs Neovim (winget Neovim.Neovim) and links windows/nvim
# - Backups existing profile
# - Validates PowerShell installation
# - Syntax checking
#
# Prerequisites (manual installation):
# - Oh My Posh: winget install JanDeDobbeleer.OhMyPosh
#
# Recommended font setting:
# - 'Moralerspace Argon HWJPDOC', 'Consolas', monospace

param(
    [string]$Action = "install",
    [string]$GlazewmProfile = "sugimoto-pc"
)

$UserProfile = [Environment]::GetFolderPath("UserProfile")
$UserBinPath = Join-Path $UserProfile "bin"
$WindowsPath = Split-Path -Parent $PSCommandPath
$DotfilesPath = Split-Path -Parent $WindowsPath
$SymlinkFallbackMessage = "Symbolic link creation failed, falling back to file copy."

# Colors for output
$ErrorActionPreference = "Continue"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Backup-AndRemoveItem {
    param(
        [string]$Path,
        [string]$Description
    )

    if (Test-Path $Path) {
        $backupPath = "$Path.backup"
        Write-ColorOutput "Backing up existing ${Description}: $Path -> $backupPath" "Yellow"
        $item = Get-Item $Path -Force
        if ($item.PSIsContainer) {
            Copy-Item $Path $backupPath -Force -Recurse
            Remove-Item $Path -Recurse -Force
        } else {
            Copy-Item $Path $backupPath -Force
            Remove-Item $Path -Force
        }
    }
}

function Set-SymbolicLinkOrCopy {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Description
    )

    $sourceItem = Get-Item $SourcePath -Force
    $isDirectory = $sourceItem.PSIsContainer

    try {
        New-Item -ItemType SymbolicLink -Path $DestinationPath -Target $SourcePath -Force -ErrorAction Stop | Out-Null
        Write-ColorOutput "$Description linked successfully!" "Green"
        Write-ColorOutput "Link: $DestinationPath -> $SourcePath" "Blue"
        return $true
    } catch {
        Write-ColorOutput "Failed to create symbolic link for ${Description}: $($_.Exception.Message)" "Yellow"

        if ($isDirectory) {
            try {
                New-Item -ItemType Junction -Path $DestinationPath -Target $SourcePath -Force -ErrorAction Stop | Out-Null
                Write-ColorOutput "$Description junction created successfully!" "Green"
                Write-ColorOutput "Junction: $DestinationPath -> $SourcePath" "Blue"
                return $true
            } catch {
                Write-ColorOutput "Failed to create junction for ${Description}: $($_.Exception.Message)" "Yellow"
            }
        }

        Write-ColorOutput $SymlinkFallbackMessage "Yellow"

        try {
            if ($isDirectory) {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force
            } else {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
            }
            Write-ColorOutput "$Description copied successfully!" "Green"
            Write-ColorOutput "Copy: $SourcePath -> $DestinationPath" "Blue"
            return $true
        } catch {
            Write-ColorOutput "Failed to copy ${Description}: $($_.Exception.Message)" "Red"
            return $false
        }
    }
}

function Test-PowerShellInstallation {
    Write-ColorOutput "Checking PowerShell installation..." "Blue"
    
    try {
        $version = $PSVersionTable.PSVersion
        Write-ColorOutput "PowerShell found: $version" "Green"
        return $true
    } catch {
        Write-ColorOutput "PowerShell not found. Please install PowerShell Core." "Red"
        Write-ColorOutput "Download from: https://github.com/PowerShell/PowerShell/releases" "Yellow"
        return $false
    }
}

function Initialize-UserBinDirectory {
    Write-ColorOutput "Setting up user bin directory..." "Green"
    
    $binPath = $UserBinPath
    
    # Create bin directory if it doesn't exist
    if (!(Test-Path $binPath)) {
        Write-ColorOutput "Creating bin directory: $binPath" "Blue"
        New-Item -ItemType Directory -Path $binPath -Force | Out-Null
        Write-ColorOutput "Bin directory created successfully!" "Green"
    } else {
        Write-ColorOutput "Bin directory already exists: $binPath" "Yellow"
    }
    
    # Add to PATH if not already present
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        
        if ($currentPath -notlike "*$binPath*") {
            Write-ColorOutput "Adding bin directory to user PATH..." "Blue"
            $newPath = if ($currentPath) { "$currentPath;$binPath" } else { $binPath }
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-ColorOutput "User bin directory added to PATH successfully!" "Green"
            Write-ColorOutput "" "White"
            Write-ColorOutput "NOTE: You need to restart PowerShell for PATH changes to take effect." "Yellow"
        } else {
            Write-ColorOutput "Bin directory is already in PATH" "Yellow"
        }
        
        return $true
    } catch {
        Write-ColorOutput "Failed to update PATH: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-WeztermConfig {
    Write-ColorOutput "Installing WezTerm configuration..." "Green"
    
    $weztermSourcePath = Join-Path $WindowsPath "wezterm.lua"
    $weztermDestPath = Join-Path $UserProfile ".wezterm.lua"
    
    try {
        Backup-AndRemoveItem -Path $weztermDestPath -Description "WezTerm config"
        if (Set-SymbolicLinkOrCopy -SourcePath $weztermSourcePath -DestinationPath $weztermDestPath -Description "WezTerm config") {
            return $true
        }
        
        return $false
    } catch {
        Write-ColorOutput "Failed to install WezTerm config: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-Neovim {
    Write-ColorOutput "Installing Neovim..." "Green"

    # Neovim.Neovim is a WiX MSI and has no per-user installer.
    $wingetArgs = @(
        "--id", "Neovim.Neovim",
        "--exact",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    & winget install @wingetArgs
    $installExit = $LASTEXITCODE
    if ($installExit -ne 0) {
        & winget list --id Neovim.Neovim --exact --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "winget install Neovim.Neovim failed (exit $installExit)" "Red"
            return $false
        }
        Write-ColorOutput "Neovim is already installed" "Yellow"
    }

    $sourcePath = Join-Path $WindowsPath "nvim"
    $destPath = Join-Path $env:LOCALAPPDATA "nvim"

    if (!(Test-Path $sourcePath)) {
        Write-ColorOutput "Neovim config not found: $sourcePath" "Red"
        return $false
    }

    try {
        Backup-AndRemoveItem -Path $destPath -Description "Neovim config"
        if (!(Set-SymbolicLinkOrCopy -SourcePath $sourcePath -DestinationPath $destPath -Description "Neovim config")) {
            return $false
        }
        Write-ColorOutput "Open a new terminal if nvim is not on PATH yet." "Yellow"
        return $true
    } catch {
        Write-ColorOutput "Failed to install Neovim config: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-WslConfig {
    Write-ColorOutput "Installing WSL configuration..." "Green"
    
    $wslSourcePath = Join-Path $WindowsPath "wslconfig"
    $wslDestPath = Join-Path $UserProfile ".wslconfig"
    
    try {
        # Check if source file exists
        if (!(Test-Path $wslSourcePath)) {
            Write-ColorOutput "WSL config not found: $wslSourcePath" "Yellow"
            Write-ColorOutput "Skipping WSL config installation" "Yellow"
            return $false
        }
        
        Backup-AndRemoveItem -Path $wslDestPath -Description "WSL config"
        
        if (Set-SymbolicLinkOrCopy -SourcePath $wslSourcePath -DestinationPath $wslDestPath -Description "WSL config") {
            Write-ColorOutput "" "White"
            Write-ColorOutput "NOTE: Restart WSL to apply WSL changes:" "Yellow"
            Write-ColorOutput "  wsl --shutdown" "Cyan"
            return $true
        }
        
        return $false
    } catch {
        Write-ColorOutput "Failed to install WSL config: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Install-MoralerspaceFont {
    Write-ColorOutput "Installing Moralerspace HWJPDOC font..." "Green"
    
    $fontUrl = "https://github.com/yuru7/moralerspace/releases/download/v2.0.0/MoralerspaceHWJPDOC_v2.0.0.zip"
    $tempDir = Join-Path $env:TEMP "MoralerspaceFont"
    $zipPath = Join-Path $tempDir "moralerspace.zip"
    $extractPath = Join-Path $tempDir "extracted"
    
    try {
        # Create temp directory
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        # Download font
        Write-ColorOutput "Downloading font from GitHub..." "Blue"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $fontUrl -OutFile $zipPath -ErrorAction Stop
        Write-ColorOutput "Download completed" "Green"
        
        # Extract zip
        Write-ColorOutput "Extracting font files..." "Blue"
        if (Test-Path $extractPath) {
            Remove-Item -Recurse -Force $extractPath
        }
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Install fonts to user directory (no admin rights required)
        Write-ColorOutput "Installing font files to user directory..." "Blue"
        $fontFiles = Get-ChildItem -Path $extractPath -Recurse -Include "*.ttf", "*.otf"
        $userFontsFolder = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
        
        # Create user fonts folder if it doesn't exist
        if (!(Test-Path $userFontsFolder)) {
            New-Item -ItemType Directory -Path $userFontsFolder -Force | Out-Null
        }
        
        $installedCount = 0
        
        foreach ($fontFile in $fontFiles) {
            try {
                $destPath = Join-Path $userFontsFolder $fontFile.Name
                
                # Check if font already exists
                if (Test-Path $destPath) {
                    Write-ColorOutput "  $($fontFile.Name) already installed (skipping)" "Yellow"
                } else {
                    Copy-Item -Path $fontFile.FullName -Destination $destPath -Force
                    
                    # Register font in user registry
                    $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fontFile.Name)
                    $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                    
                    # Ensure registry path exists
                    if (!(Test-Path $registryPath)) {
                        New-Item -Path $registryPath -Force | Out-Null
                    }
                    
                    New-ItemProperty -Path $registryPath -Name "$fontName (TrueType)" -Value $destPath -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
                    
                    Write-ColorOutput "  Installed: $($fontFile.Name)" "Green"
                    $installedCount++
                }
            } catch {
                Write-ColorOutput "  Failed to install $($fontFile.Name): $($_.Exception.Message)" "Red"
            }
        }
        
        Write-ColorOutput "Font installation completed! ($installedCount new fonts installed)" "Green"
        
        # Cleanup
        Write-ColorOutput "Cleaning up temporary files..." "Blue"
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-ColorOutput "Failed to install font: $($_.Exception.Message)" "Red"
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
        return $false
    }
}

function Install-GlazewmProfile {
    param(
        [string]$SourceDir,
        [string]$DestinationRoot
    )

    $glazewmDestDir = Join-Path $DestinationRoot "glazewm"
    if (!(Test-Path $glazewmDestDir)) {
        Write-ColorOutput "Creating destination glazewm directory: $glazewmDestDir" "Blue"
        New-Item -ItemType Directory -Path $glazewmDestDir -Force | Out-Null
    }

    $profilesSourceDir = Join-Path $SourceDir "profiles"
    if (!(Test-Path $profilesSourceDir)) {
        Write-ColorOutput "Glazewm profiles directory not found: $profilesSourceDir" "Red"
        return $false
    }

    $profilesDestPath = Join-Path $glazewmDestDir "profiles"
    Backup-AndRemoveItem -Path $profilesDestPath -Description "glazewm profiles"
    if (!(Set-SymbolicLinkOrCopy -SourcePath $profilesSourceDir -DestinationPath $profilesDestPath -Description "glazewm profiles directory")) {
        return $false
    }

    $selectedProfileName = $(if ([string]::IsNullOrWhiteSpace($GlazewmProfile)) { "default" } else { $GlazewmProfile })
    if ($selectedProfileName -notmatch '\.ya?ml$') {
        $selectedProfileName = "$selectedProfileName.yaml"
    }

    $profileSourcePath = Join-Path $profilesSourceDir $selectedProfileName
    if (!(Test-Path $profileSourcePath)) {
        Write-ColorOutput "Glazewm profile not found: $selectedProfileName" "Yellow"
        $availableProfiles = Get-ChildItem -Path $profilesSourceDir -Filter *.yaml
        if ($availableProfiles.Count -eq 0) {
            Write-ColorOutput "No glazewm profiles available in $profilesSourceDir" "Red"
            return $false
        }
        $profileSourcePath = $availableProfiles[0].FullName
        $selectedProfileName = $availableProfiles[0].Name
        Write-ColorOutput "Falling back to profile: $selectedProfileName" "Yellow"
    }

    $configDestPath = Join-Path $glazewmDestDir "config.yaml"
    Backup-AndRemoveItem -Path $configDestPath -Description "glazewm config"
    if (!(Set-SymbolicLinkOrCopy -SourcePath $profileSourcePath -DestinationPath $configDestPath -Description "glazewm config ($selectedProfileName)")) {
        return $false
    }

    Write-ColorOutput "Glazewm profile applied: $selectedProfileName" "Green"
    return $true
}

function Install-GlzrConfigs {
    Write-ColorOutput "Installing .glzr configurations..." "Green"

    $glzrSourcePath = Join-Path $WindowsPath "glzr"
    if (!(Test-Path $glzrSourcePath)) {
        Write-ColorOutput ".glzr source directory not found: $glzrSourcePath" "Yellow"
        return $false
    }

    $glzrDestRoot = Join-Path $UserProfile ".glzr"
    if (!(Test-Path $glzrDestRoot)) {
        Write-ColorOutput "Creating destination .glzr directory: $glzrDestRoot" "Blue"
        New-Item -ItemType Directory -Path $glzrDestRoot -Force | Out-Null
    }

    $glazewmSourceDir = Join-Path $glzrSourcePath "glazewm"
    if (Test-Path $glazewmSourceDir) {
        if (!(Install-GlazewmProfile -SourceDir $glazewmSourceDir -DestinationRoot $glzrDestRoot)) {
            Write-ColorOutput "Failed to install glazewm profile configuration" "Red"
            return $false
        }
    }

    $items = Get-ChildItem -Path $glzrSourcePath -Force | Where-Object { $_.Name -ne "glazewm" }
    if ($items.Count -eq 0) {
        Write-ColorOutput ".glzr source directory is empty" "Yellow"
        return $true
    }

    foreach ($item in $items) {
        $destPath = Join-Path $glzrDestRoot $item.Name
        if ($item.PSIsContainer) {
            $shouldRecreateDirectory = $false
            if (Test-Path $destPath) {
                $existingDest = Get-Item $destPath -Force
                if ($existingDest.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    Backup-AndRemoveItem -Path $destPath -Description ".glzr\$($item.Name)"
                    $shouldRecreateDirectory = $true
                }
            } else {
                $shouldRecreateDirectory = $true
            }

            if ($shouldRecreateDirectory) {
                Write-ColorOutput "Ensuring destination directory exists: $destPath" "Blue"
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }

            $childItems = Get-ChildItem -Path $item.FullName -Force
            foreach ($child in $childItems) {
                $childDestPath = Join-Path $destPath $child.Name
                Backup-AndRemoveItem -Path $childDestPath -Description ".glzr\$($item.Name)\$($child.Name)"
                if (!(Set-SymbolicLinkOrCopy -SourcePath $child.FullName -DestinationPath $childDestPath -Description ".glzr\$($item.Name)\$($child.Name)")) {
                    return $false
                }
            }
        } else {
            Backup-AndRemoveItem -Path $destPath -Description ".glzr\$($item.Name)"
            if (!(Set-SymbolicLinkOrCopy -SourcePath $item.FullName -DestinationPath $destPath -Description ".glzr\$($item.Name)")) {
                return $false
            }
        }
    }

    Write-ColorOutput ".glzr configurations installed successfully!" "Green"
    return $true
}

function Install-PowerShellModules {
    Write-ColorOutput "Installing PowerShell modules..." "Green"
    
    $modules = @("Terminal-Icons", "posh-git")
    
    foreach ($module in $modules) {
        Write-ColorOutput "Installing $module..." "Blue"
        try {
            if (Get-Module -ListAvailable -Name $module) {
                Write-ColorOutput "$module is already installed" "Yellow"
            } else {
                Install-Module -Name $module -Repository PSGallery -Force -Scope CurrentUser -ErrorAction Stop
                Write-ColorOutput "$module installed successfully!" "Green"
            }
        } catch {
            Write-ColorOutput "Failed to install ${module}: $($_.Exception.Message)" "Red"
            return $false
        }
    }
    
    return $true
}

function Install-PowerShellProfile {
    Write-ColorOutput "Installing PowerShell profile..." "Green"
    
    $profilePath = $PROFILE
    $wslSourcePath = Join-Path $WindowsPath "Microsoft.PowerShell_profile.ps1"
    
    # Create profile directory if it doesn't exist
    $profileDir = Split-Path $profilePath -Parent
    if (!(Test-Path $profileDir)) {
        Write-ColorOutput "Creating profile directory: $profileDir" "Blue"
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Backup existing profile
    if (Test-Path $profilePath) {
        Backup-AndRemoveItem -Path $profilePath -Description "PowerShell profile"
    }
    
    # Setup user bin directory
    Write-ColorOutput "" "White"
    Initialize-UserBinDirectory
    
    # Install required modules
    if (!(Install-PowerShellModules)) {
        Write-ColorOutput "Warning: Some modules failed to install" "Yellow"
    }
    
    # Install Moralerspace font
    Write-ColorOutput "" "White"
    Write-ColorOutput "Installing Moralerspace HWJPDOC font (recommended for Japanese + programming)..." "Yellow"
    if (!(Install-MoralerspaceFont)) {
        Write-ColorOutput "Warning: Font installation failed, but continuing..." "Yellow"
    }
    
    # Install WezTerm config
    Write-ColorOutput "" "White"
    if (!(Install-WeztermConfig)) {
        Write-ColorOutput "Warning: WezTerm config installation failed, but continuing..." "Yellow"
    }

    # Install Neovim and link the Windows config
    Write-ColorOutput "" "White"
    if (!(Install-Neovim)) {
        Write-ColorOutput "Warning: Neovim installation failed, but continuing..." "Yellow"
    }
    
    # Install WSL config
    Write-ColorOutput "" "White"
    if (!(Install-WslConfig)) {
        Write-ColorOutput "Warning: WSL config installation failed, but continuing..." "Yellow"
    }
    
    # Install Glzr configs
    Write-ColorOutput "" "White"
    if (!(Install-GlzrConfigs)) {
        Write-ColorOutput "Warning: .glzr configuration installation failed, but continuing..." "Yellow"
    }
    
    # Copy profile from WSL
    try {
        Write-ColorOutput "" "White"
        if (!(Set-SymbolicLinkOrCopy -SourcePath $wslSourcePath -DestinationPath $profilePath -Description "PowerShell profile")) {
            return $false
        }
        Write-ColorOutput "PowerShell profile installed successfully!" "Green"
        Write-ColorOutput "Profile location: $profilePath" "Blue"
        Write-ColorOutput "" "White"
        Write-ColorOutput "NOTE: Oh My Posh must be installed manually." "Yellow"
        Write-ColorOutput "Run: winget install JanDeDobbeleer.OhMyPosh" "Cyan"
        Write-ColorOutput "" "White"
        Write-ColorOutput "Next steps:" "Yellow"
        Write-ColorOutput "1. Restart Windows Terminal (font needs refresh)" "Cyan"
        Write-ColorOutput "2. Switch to WezTerm for the ultimate terminal experience! 🚀" "Magenta"
        Write-ColorOutput "   - Semi-transparent background (85% opacity)" "Gray"
        Write-ColorOutput "   - Catppuccin Mocha theme (cool dark theme)" "Gray"
        Write-ColorOutput "   - WSL Arch Linux as default" "Gray"
        Write-ColorOutput "3. Or set font in Windows Terminal:" "Cyan"
        Write-ColorOutput "   Ctrl+, -> Profiles -> PowerShell -> Appearance -> Font face:" "Gray"
        Write-ColorOutput "   'Moralerspace Neon HWJPDOC'" "White"
        Write-ColorOutput "4. WSL config installed - Restart WSL for GUI app optimization:" "Cyan"
        Write-ColorOutput "   wsl --shutdown" "Gray"
        Write-ColorOutput "5. Reload profile: reload or restart PowerShell" "Cyan"
        Write-ColorOutput "6. Your theme is set to: powerlevel10k_rainbow" "Magenta"
        Write-ColorOutput "" "White"
        Write-ColorOutput "To reload the profile, run: reload" "Yellow"
        return $true
    } catch {
        Write-ColorOutput "Failed to copy profile: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Uninstall-PowerShellProfile {
    Write-ColorOutput "Uninstalling PowerShell profile..." "Yellow"
    
    $profilePath = $PROFILE
    
    if (Test-Path $profilePath) {
        Write-ColorOutput "Removing profile: $profilePath" "Green"
        Remove-Item $profilePath -Force
        Write-ColorOutput "PowerShell profile uninstalled successfully!" "Green"
    } else {
        Write-ColorOutput "No PowerShell profile found" "Yellow"
    }
}

function Test-PowerShellProfile {
    Write-ColorOutput "Testing PowerShell profile..." "Blue"
    
    $profilePath = $PROFILE
    
    if (Test-Path $profilePath) {
        Write-ColorOutput "Profile file exists: $profilePath" "Green"
        
        # Test syntax
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $profilePath -Raw), [ref]$null)
            Write-ColorOutput "Profile syntax is valid" "Green"
        } catch {
            Write-ColorOutput "Profile syntax error: $($_.Exception.Message)" "Red"
        }
    } else {
        Write-ColorOutput "Profile file not found: $profilePath" "Red"
    }
}

function Show-Help {
    Write-ColorOutput "PowerShell Profile Installer" "Cyan"
    Write-ColorOutput "=============================" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Usage: .\install-powershell.ps1 [install|uninstall|test|check|font|wezterm|wsl|nvim|help]" "White"
    Write-ColorOutput "       .\install-powershell.ps1 install -GlazewmProfile thinkpad" "DarkGray"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Options:" "Yellow"
    Write-ColorOutput "  -GlazewmProfile <name>  - Apply glazewm profile from glzr\glazewm\profiles (default: sugimoto-pc)" "White"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Commands:" "Yellow"
    Write-ColorOutput "  install   - Install PowerShell profile + modules + Moralerspace font + WezTerm + WSL config + Neovim" "White"
    Write-ColorOutput "  uninstall - Remove PowerShell profile" "White"
    Write-ColorOutput "  test      - Test PowerShell profile syntax" "White"
    Write-ColorOutput "  check     - Check PowerShell installation" "White"
    Write-ColorOutput "  font      - Install Moralerspace HWJPDOC font only" "White"
    Write-ColorOutput "  wezterm   - Install WezTerm config only" "White"
    Write-ColorOutput "  wsl       - Install WSL config only" "White"
    Write-ColorOutput "  nvim      - Install Neovim and link windows/nvim only" "White"
    Write-ColorOutput "  help      - Show this help message" "White"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Prerequisites (manual installation):" "Yellow"
    Write-ColorOutput "  • Oh My Posh:  winget install JanDeDobbeleer.OhMyPosh" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Auto-installed items:" "Yellow"
    Write-ColorOutput "  • User bin directory   - $UserBinPath (added to PATH)" "White"
    Write-ColorOutput "  • Terminal-Icons       - Colorful file/folder icons" "White"
    Write-ColorOutput "  • posh-git             - Enhanced Git integration" "White"
    Write-ColorOutput "  • Moralerspace HWJPDOC - Japanese programming font" "White"
    Write-ColorOutput "  • WezTerm config       - Cool terminal emulator config with transparency" "White"
    Write-ColorOutput "  • WSL config          - WSL GUI optimization for Ghostty/GTK apps" "White"
    Write-ColorOutput "  • Neovim              - winget Neovim.Neovim, config at %LOCALAPPDATA%\nvim" "White"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Recommended font setting:" "Yellow"
    Write-ColorOutput "  'Moralerspace Argon HWJPDOC', 'Consolas', monospace" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "Note: The bin directory is used for custom tools and scripts" "Gray"
    Write-ColorOutput "" "White"
    Write-ColorOutput "WSL config requires WSL restart:" "Gray"
    Write-ColorOutput "  wsl --shutdown" "DarkGray"
}

# Main script logic
switch ($Action.ToLower()) {
    "install" {
        if (Test-PowerShellInstallation) {
            Install-PowerShellProfile
        }
    }
    "uninstall" {
        Uninstall-PowerShellProfile
    }
    "test" {
        Test-PowerShellProfile
    }
    "check" {
        Test-PowerShellInstallation
    }
    "font" {
        Install-MoralerspaceFont
    }
    "wezterm" {
        Install-WeztermConfig
    }
    "wsl" {
        Install-WslConfig
    }
    "nvim" {
        Install-Neovim
    }
    "help" {
        Show-Help
    }
    default {
        Write-ColorOutput "Unknown option: $Action" "Red"
        Show-Help
        exit 1
    }
}