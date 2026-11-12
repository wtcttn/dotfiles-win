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

# Bitwarden の解錠した鍵（BW_SESSION）を返す。鍵は DPAPI（この Windows ユーザーだけが戻せる）で暗号化して
# %LOCALAPPDATA%\cc\bw-session.json に 12 時間だけ置き、ペインを起動するたびにマスターパスワードを聞かないようにする。
# 期限が過ぎたら bw lock で鍵を無効にして聞き直す。手で bw lock したときも、鍵が効かないので聞き直す。
function Get-BwSession {
    $cacheDir = Join-Path $env:LOCALAPPDATA "cc"
    $cacheFile = Join-Path $cacheDir "bw-session.json"
    $ttlHours = 12

    if (Test-Path $cacheFile) {
        try {
            $cache = Get-Content -Raw $cacheFile | ConvertFrom-Json
            if ([datetime]$cache.expires -gt (Get-Date)) {
                $secure = ConvertTo-SecureString $cache.key
                $key = [System.Net.NetworkCredential]::new("", $secure).Password
                if ((bw status --session $key | ConvertFrom-Json).status -eq "unlocked") {
                    return $key
                }
            } else {
                bw lock | Out-Null
            }
        } catch {
        }
        Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
    }

    $key = bw unlock --raw
    if (!$key) { return $null }
    if (!(Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
    @{
        expires = (Get-Date).AddHours($ttlHours).ToString("o")
        key = ConvertTo-SecureString $key -AsPlainText -Force | ConvertFrom-SecureString
    } | ConvertTo-Json | Set-Content -Path $cacheFile -Encoding utf8
    Write-Host "Bitwarden を解錠しました（$ttlHours 時間、ほかのペインはパスワードなしで起動できます）。" -ForegroundColor Green
    return $key
}

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
        $env:BW_SESSION = Get-BwSession
        if (!$env:BW_SESSION) {
            Write-Host "Bitwarden の解錠に失敗しました。" -ForegroundColor Red
            return
        }
        # 別の端末やアプリで直した値を読むため、手元の控えを先に同期する。
        bw sync --session $env:BW_SESSION 2>$null | Out-Null
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

    # claude/workspaces/<フォルダ>/channels にあるチャネル（1行に1つ。hub の hub-bridge など）を読み込む。
    # 自作のチャネルは研究プレビューの間、--dangerously-load-development-channels でしか読み込めない。
    $claudeArgs = @("-n", $Name)
    $channelsFile = Join-Path $env:USERPROFILE "dotfiles\claude\workspaces\$Folder\channels"
    if (Test-Path $channelsFile) {
        foreach ($ch in @(Get-Content $channelsFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -and !$_.StartsWith("#") })) {
            $claudeArgs += @("--dangerously-load-development-channels", $ch)
        }
    }

    $Host.UI.RawUI.WindowTitle = $Name
    claude @claudeArgs
}

# Welcome message (fastfetch config: windows/fastfetch/config.jsonc)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
} else {
    Write-Host "🚀 PowerShell Profile Loaded!" -ForegroundColor Green
    Write-Host "   Theme: Custom (ohmyposh-theme.omp.json) | Font: Moralerspace Neon" -ForegroundColor Cyan
    Write-Host "   Modules: Terminal-Icons, posh-git, PSReadLine" -ForegroundColor Gray
}
