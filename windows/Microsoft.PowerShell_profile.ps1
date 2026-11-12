# PowerShell Profile Configuration
# This file is managed by dotfiles repository

# Set execution policy for current user (if needed)
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 入出力が端末でないとき（Grok Bot のデスクトップアプリやタスクスケジューラから pwsh -Command で呼ばれたとき）は、
# 画面まわりの設定（PSReadLine、fastfetch）を飛ばして、関数（cc、ccs、ccx、Start-Hub など）だけを読み込む。
$script:InteractiveShell = -not ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected)

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
if ($script:InteractiveShell -and (Get-Module -ListAvailable -Name PSReadLine)) {
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

    # Claude Code が終わったら、タブ名を外す（残っていると ccs が「もうある」と勘違いする）。
    if ($env:WEZTERM_PANE -and (Get-Command wezterm -ErrorAction SilentlyContinue)) {
        wezterm cli set-tab-title --pane-id $env:WEZTERM_PANE "" 2>$null | Out-Null
    }
}

# mux の中から、タブ名（cc と ccs が付ける）が <名前> のペインを探す。タブ名の無い古いペインは、タイトルの末尾の名前で探す。
# mux のサーバーが動いていなければ、wezterm cli が起動する（画面は開かない）。
function Get-MuxPanes {
    if (!(Get-Command wezterm -ErrorAction SilentlyContinue)) { return @() }
    # wezterm の出力は UTF-8。タイトルの記号（◑ など）を読み違えないように合わせる。
    $prevEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    try {
        return @(wezterm cli --prefer-mux list --format json | ConvertFrom-Json)
    } finally {
        [Console]::OutputEncoding = $prevEncoding
    }
}

function Find-CcPane {
    param([Parameter(Mandatory)][string]$Name)
    $pattern = "(^|\s)$([regex]::Escape($Name))$"
    return Get-MuxPanes | Where-Object { $_.tab_title -eq $Name -or (!$_.tab_title -and $_.title -match $pattern) } | Select-Object -First 1
}

# Claude Code の常駐ペインを WezTerm の mux（ウィンドウを閉じても残る）に用意する（例: ccs blender、ccs blender-anim cg）。
# mux に同じ名前のペインがあれば何もしない。無ければ mux の既存のウィンドウにタブを足し、その中で cc <名前> [<フォルダ>] を起動する。
# mux にウィンドウが1つも無いときだけ、ウィンドウを1つ作る。呼び出し元（hub のペイン、ふつうのタブ、Grok Bot、タスクスケジューラ）に関係なく、
# ウィンドウは増えない（2026-11-12 に、mux の中からも外からも、spawn で mux が固まらないことを確かめた）。
# Bitwarden の解錠の控えが切れていれば、新しいペインでマスターパスワードを聞かれるので、そのペインで入力する。
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
    # 呼び出し元のペインには頼らず、mux の既存のウィンドウを指定する（ふつうのタブのペインは mux に無いため）。
    $windowId = Get-MuxPanes | Select-Object -ExpandProperty window_id -First 1
    $where = if ($null -ne $windowId) { @("--window-id", "$windowId") } else { @("--new-window") }
    $out = @(wezterm cli --prefer-mux spawn @where --cwd $dir -- pwsh -NoLogo -NoExit -Command $ccCommand 2>&1 | ForEach-Object { "$_" })
    $paneId = $out | Where-Object { $_ -match '^\s*\d+\s*$' } | Select-Object -Last 1
    if ($paneId) {
        $paneId = $paneId.Trim()
        wezterm cli --prefer-mux set-tab-title --pane-id $paneId $Name | Out-Null
        Write-Host "$Name を mux に用意しました（pane $paneId、フォルダ $Folder）。" -ForegroundColor Green
        return $paneId
    }
    Write-CcsLog "spawn $($where -join ' ') に失敗: $($out -join ' / ')"

    # mux にウィンドウが1つも無く、新しいウィンドウも作れなかったとき（2026-11-12、hub を閉じて mux が空になったときに起きた）。
    # WezTerm の画面を1つ開いて mux につなぎ、その最初のタブで cc を起動する。画面が開くのはこのときだけ。
    if ($null -eq $windowId) {
        Start-Process wezterm -ArgumentList (@("connect", "mux", "--", "pwsh", "-NoLogo", "-NoExit", "-Command", "Set-Location '$dir'; $ccCommand"))
        for ($i = 0; $i -lt 20; $i++) {
            Start-Sleep -Seconds 1
            $found = Find-CcPane $Name
            if ($found) {
                Write-Host "$Name を WezTerm の画面を開いて mux に用意しました（pane $($found.pane_id)、フォルダ $Folder）。" -ForegroundColor Green
                return $found.pane_id
            }
        }
        Write-CcsLog "wezterm connect mux のあと 20 秒たっても $Name のペインが見えない"
    }
    Write-Host "mux にペインを足せませんでした（記録: $(Join-Path $env:LOCALAPPDATA 'cc\ccs.log')）。" -ForegroundColor Red
    Write-Host ($out -join "`n") -ForegroundColor DarkGray
    return
}

# ccs の失敗を %LOCALAPPDATA%\cc\ccs.log に残す（Grok Bot から呼んだときなど、画面が見えないときに原因を追うため）。
function Write-CcsLog {
    param([string]$Message)
    $dir = Join-Path $env:LOCALAPPDATA "cc"
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path (Join-Path $dir "ccs.log") -Value "$(Get-Date -Format o) $Message" -Encoding utf8
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
if (!$script:InteractiveShell) {
    # 端末でないときは何も表示しない
} elseif (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
} else {
    Write-Host "🚀 PowerShell Profile Loaded!" -ForegroundColor Green
    Write-Host "   Theme: Custom (ohmyposh-theme.omp.json) | Font: Moralerspace Neon" -ForegroundColor Cyan
    Write-Host "   Modules: Terminal-Icons, posh-git, PSReadLine" -ForegroundColor Gray
}
