# PowerShell Profile Configuration
# This file is managed by dotfiles repository

# Set execution policy for current user (if needed)
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Import modules
Import-Module PSReadLine -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module posh-git -ErrorAction SilentlyContinue

# Initialize Oh My Posh with a theme
try {
    # Use custom theme from dotfiles
    $customTheme = Join-Path $env:USERPROFILE "dotfiles\windows\ohmyposh-theme.omp.json"
    if (Test-Path $customTheme) {
        oh-my-posh init pwsh --config $customTheme | Invoke-Expression
    } else {
        # Fallback to default theme
        oh-my-posh init pwsh | Invoke-Expression
    }
} catch {
    Write-Host "⚠️  Oh My Posh not configured. Using basic prompt." -ForegroundColor Yellow
}

# PSReadLine configuration
if (Get-Module -ListAvailable -Name PSReadLine) {
    # Enable prediction
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    
    # Enable syntax highlighting
    Set-PSReadLineOption -Colors @{
        Command = 'Cyan'
        Parameter = 'Gray'
        Operator = 'Magenta'
        Variable = 'Green'
        String = 'Yellow'
        Number = 'Red'
        Type = 'Blue'
        Comment = 'DarkGreen'
    }
    
    # Key bindings
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
    Set-PSReadLineKeyHandler -Key Ctrl+z -Function Undo
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# Aliases
# Note: ls is handled by Terminal-Icons module automatically
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name grep -Value Select-String
Set-Alias -Name which -Value Get-Command

# Git shortcuts
# Note: posh-git provides enhanced Git info in prompt
function gst { git status }

# Navigation shortcuts
function .. { Set-Location .. }
function ... { Set-Location ..\.. }

# Profile management
function Edit-Profile { code $PROFILE }
function Import-Profile { . $PROFILE }
Set-Alias -Name reload -Value Import-Profile

# Environment variables
$env:EDITOR = "code"

# Welcome message
Write-Host "🚀 PowerShell Profile Loaded!" -ForegroundColor Green
Write-Host "   Theme: Custom (ohmyposh-theme.omp.json) | Font: Moralerspace Neon" -ForegroundColor Cyan
Write-Host "   Modules: Terminal-Icons, posh-git, PSReadLine" -ForegroundColor Gray
