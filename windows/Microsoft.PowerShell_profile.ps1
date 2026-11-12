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
# -Resume で同じ名前の前の会話を、-ResumeId <会話の ID か名前> でその会話を再開する。
# Remote Control は既定でオン（セッション名は <名前>）。-NoRemoteControl で切る。
function cc {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Folder,
        [switch]$Resume,
        [string]$ResumeId,
        [switch]$NoRemoteControl
    )
    $paneFolders = @{ blender = "cg"; aftereffects = "cg" }
    if (!$Folder) { $Folder = if ($paneFolders.ContainsKey($Name)) { $paneFolders[$Name] } else { $Name } }
    $dir = Join-Path $env:USERPROFILE "workspace\$Folder"
    if (!(Test-Path $dir)) {
        Write-Host "フォルダがありません: $dir" -ForegroundColor Red
        return
    }
    Set-Location $dir

    # ほかのペイン（hub が ccs で立ち上げたときなど）から引き継いだ秘密と Claude Code の印を消してから始める。
    # 消すのは BW_SESSION、どれかの secrets.bw に書いてある環境変数、CLAUDE で始まるもの。
    $inherited = @("BW_SESSION")
    foreach ($sf in @(Get-ChildItem (Join-Path $env:USERPROFILE "dotfiles\claude\workspaces\*\secrets.bw") -ErrorAction SilentlyContinue)) {
        $inherited += @(Get-Content $sf | Where-Object { $_ -match '^\s*[A-Za-z_][A-Za-z0-9_]*\s*=' } | ForEach-Object { $_.Split("=", 2)[0].Trim() })
    }
    Get-ChildItem Env: | Where-Object { $_.Name -like "CLAUDE*" -or $inherited -contains $_.Name } | Remove-Item -ErrorAction SilentlyContinue

    # WezTerm のタブ名を付ける（ccs がこの名前でペインを探す）。
    if ($env:WEZTERM_PANE -and (Get-Command wezterm -ErrorAction SilentlyContinue)) {
        wezterm cli set-tab-title --pane-id $env:WEZTERM_PANE $Name 2>$null | Out-Null
    }

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
    if ($ResumeId) { $claudeArgs += @("--resume", $ResumeId) }
    elseif ($Resume) { $claudeArgs += @("--resume", $Name) }
    if (!$NoRemoteControl) { $claudeArgs += @("--remote-control", $Name) }
    $channelsFile = Join-Path $env:USERPROFILE "dotfiles\claude\workspaces\$Folder\channels"
    if (Test-Path $channelsFile) {
        foreach ($ch in @(Get-Content $channelsFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -and !$_.StartsWith("#") })) {
            $claudeArgs += @("--dangerously-load-development-channels", $ch)
        }
    }

    $Host.UI.RawUI.WindowTitle = $Name
    claude @claudeArgs
}

# Claude Code の常駐ペインを WezTerm の mux（ウィンドウを閉じても残る）に用意する（例: ccs blender、ccs blender-anim cg）。
# mux に同じ名前のペインがあれば何もしない。無ければ mux にペインを足し、その中で cc <名前> [<フォルダ>] を起動する。
# hub はこれでほかのペインを立ち上げる（2026-11-12 に、mux の中からの spawn で mux が固まらないことを確かめた）。
# Bitwarden の解錠の控えが切れていれば、新しいペインでマスターパスワードを聞かれるので、そのペインで入力する。
# mux の中から、タブ名（cc と ccs が付ける）が <名前> のペインを探す。タブ名の無い古いペインは、タイトルの末尾の名前で探す。
function Find-CcPane {
    param([Parameter(Mandatory)][string]$Name)
    if (!(Get-Command wezterm -ErrorAction SilentlyContinue)) { return $null }
    # wezterm の出力は UTF-8。タイトルの記号（◑ など）を読み違えないように合わせる。
    $prevEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    try {
        $panes = @(wezterm cli --prefer-mux list --format json | ConvertFrom-Json)
    } finally {
        [Console]::OutputEncoding = $prevEncoding
    }
    $pattern = "(^|\s)$([regex]::Escape($Name))$"
    return $panes | Where-Object { $_.tab_title -eq $Name -or (!$_.tab_title -and $_.title -match $pattern) } | Select-Object -First 1
}

function ccs {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Folder,
        [switch]$Resume,
        [string]$ResumeId,
        [switch]$NoRemoteControl
    )
    if (!(Get-Command wezterm -ErrorAction SilentlyContinue)) {
        Write-Host "wezterm が見つかりません。" -ForegroundColor Red
        return
    }
    $found = Find-CcPane $Name
    if ($found) {
        Write-Host "$Name はもう mux にあります（pane $($found.pane_id)）。" -ForegroundColor Yellow
        return $found.pane_id
    }
    $paneFolders = @{ blender = "cg"; aftereffects = "cg" }
    if (!$Folder) { $Folder = if ($paneFolders.ContainsKey($Name)) { $paneFolders[$Name] } else { $Name } }
    $dir = Join-Path $env:USERPROFILE "workspace\$Folder"
    if (!(Test-Path $dir)) {
        Write-Host "フォルダがありません: $dir" -ForegroundColor Red
        return
    }
    $ccCommand = "cc $Name $Folder"
    if ($ResumeId) { $ccCommand += " -ResumeId '$($ResumeId -replace "'", "''")'" }
    elseif ($Resume) { $ccCommand += " -Resume" }
    if ($NoRemoteControl) { $ccCommand += " -NoRemoteControl" }
    $paneId = (wezterm cli --prefer-mux spawn --cwd $dir -- pwsh -NoLogo -NoExit -Command $ccCommand | Out-String).Trim()
    if (!$paneId) {
        Write-Host "mux にペインを足せませんでした。" -ForegroundColor Red
        return
    }
    wezterm cli --prefer-mux set-tab-title --pane-id $paneId $Name | Out-Null
    Write-Host "$Name を mux に用意しました（pane $paneId、フォルダ $Folder）。" -ForegroundColor Green
    return $paneId
}

# mux の常駐ペインを、タブ名で探して閉じる（例: ccx blender-anim）。中の Claude Code も終わる。
# 閉じる前に、そのペインの Claude Code に引き継ぎメモを書いてもらう（hub の CLAUDE.md の「ペインを閉じる」）。
# hub は -Force を付けたときだけ閉じる（hub の中から実行すると、hub 自身が終わる）。
function ccx {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Force
    )
    if ($Name -eq "hub" -and !$Force) {
        Write-Host "hub を閉じるときは -Force を付けてください。" -ForegroundColor Yellow
        return
    }
    $found = Find-CcPane $Name
    if (!$found) {
        Write-Host "$Name は mux にありません。" -ForegroundColor Yellow
        return
    }
    wezterm cli --prefer-mux kill-pane --pane-id $found.pane_id | Out-Null
    Write-Host "$Name を閉じました（pane $($found.pane_id)）。" -ForegroundColor Green
}

# hub を mux に用意する（無ければ起動する）。Windows へのログインのときにも使える。
function Start-Hub { ccs hub }

# Welcome message (fastfetch config: windows/fastfetch/config.jsonc)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
} else {
    Write-Host "🚀 PowerShell Profile Loaded!" -ForegroundColor Green
    Write-Host "   Theme: Custom (ohmyposh-theme.omp.json) | Font: Moralerspace Neon" -ForegroundColor Cyan
    Write-Host "   Modules: Terminal-Icons, posh-git, PSReadLine" -ForegroundColor Gray
}
