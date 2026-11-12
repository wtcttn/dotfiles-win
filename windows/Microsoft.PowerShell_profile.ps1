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

# Claude Code の常駐ペインを起動する（例: cc music、cc blender、cc blender-anim cg）。
# フォルダに移り、dotfiles の claude/workspaces/<フォルダ>/secrets.bw にある秘密を Bitwarden から読んで、
# このペインの環境変数にだけ渡してから claude -n <名前> を起動する。値はレジストリにもファイルにも残さない。
function cc {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Folder
    )
    $paneFolders = @{ blender = "cg"; aftereffects = "cg" }
    if (!$Folder) { $Folder = if ($paneFolders.ContainsKey($Name)) { $paneFolders[$Name] } else { $Name } }
    $dir = Join-Path $env:USERPROFILE "workspace\$Folder"
    if (!(Test-Path $dir)) {
        Write-Host "フォルダがありません: $dir" -ForegroundColor Red
        return
    }
    Set-Location $dir

    # secrets.bw の1行は「環境変数=Bitwarden の項目名」（項目のパスワード欄を読む）。
    # @session の行があるフォルダ（hub）だけ、Bitwarden MCP 用に BW_SESSION を残す。
    $secretsFile = Join-Path $env:USERPROFILE "dotfiles\claude\workspaces\$Folder\secrets.bw"
    $lines = @()
    if (Test-Path $secretsFile) {
        $lines = @(Get-Content $secretsFile | Where-Object { $_.Trim() -and !$_.Trim().StartsWith("#") })
    }
    if ($lines.Count -gt 0) {
        if ((bw status | ConvertFrom-Json).status -eq "unauthenticated") {
            Write-Host "Bitwarden にログインしていません。先に bw login を実行してください。" -ForegroundColor Red
            return
        }
        if (!$env:BW_SESSION) { $env:BW_SESSION = bw unlock --raw }
        if (!$env:BW_SESSION) {
            Write-Host "Bitwarden の解錠に失敗しました。" -ForegroundColor Red
            return
        }
        $keepSession = $false
        foreach ($line in $lines) {
            if ($line.Trim() -eq "@session") { $keepSession = $true; continue }
            $var, $item = $line.Split("=", 2) | ForEach-Object { $_.Trim() }
            $value = bw get password $item 2>$null
            if (!$value) {
                Write-Host "Bitwarden の項目 $item のパスワード欄が読めません（$var は空のまま）。" -ForegroundColor Yellow
                continue
            }
            Set-Item -Path "Env:$var" -Value $value
        }
        if (!$keepSession) { Remove-Item Env:BW_SESSION -ErrorAction SilentlyContinue }
    }

    $Host.UI.RawUI.WindowTitle = $Name
    claude -n $Name
}

# Welcome message (fastfetch config: windows/fastfetch/config.jsonc)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
} else {
    Write-Host "🚀 PowerShell Profile Loaded!" -ForegroundColor Green
    Write-Host "   Theme: Custom (ohmyposh-theme.omp.json) | Font: Moralerspace Neon" -ForegroundColor Cyan
    Write-Host "   Modules: Terminal-Icons, posh-git, PSReadLine" -ForegroundColor Gray
}
