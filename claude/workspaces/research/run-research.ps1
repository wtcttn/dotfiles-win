<#
.SYNOPSIS
調査の作業フォルダで Claude Code（claude -p）を動かす。Grok Bot のマーケターが PC で呼ぶ。

.DESCRIPTION
取り決めの正本は dotfiles の grokbot/claude-code.md の「調査を直接呼ぶ」。
作業フォルダ（C:\Users\kento\workspace\research\<YYYYMMDD>_<題名>\）の request_NN.md を読ませ、
report_NN.md と sources\ を書かせる。終わったら report_NN.done を書く（1行目が done <終了コード> か timeout）。

Chrome を使うとき（既定）は、ことねの巡回（8:00〜0:00 の偶数時 ±15分。おすすめの読み取りは最大約13分）と
取り合わないように、次の2つで守る。
  - 巡回の時間帯（偶数時の20分前から30分後まで）にかかる調査は始めない。次に始められる時刻を出して終了コード 3。
  - 使用中の印 C:\Users\kento\workspace\research\chrome.lock。ほかの調査が使っていれば終了コード 4。
    印は終わったら消す。期限（中に書いてある until）を過ぎた印は古いとみなして上書きする。

.EXAMPLE
& C:\Users\kento\dotfiles\claude\workspaces\research\run-research.ps1 -Dir C:\Users\kento\workspace\research\20261112_shorts_trend -N 01 -Background
  裏で動かしてすぐ戻る。report_01.done ができるまで待つ。

.EXAMPLE
& C:\Users\kento\dotfiles\claude\workspaces\research\run-research.ps1 -CheckOnly -MaxMinutes 60
  Chrome を使う60分の調査を今始められるかと、次に始められる時刻だけを出す。
#>
[CmdletBinding()]
param(
    [string]$Dir,
    [ValidatePattern('^\d{2}$')][string]$N = '01',
    [switch]$NoChrome,
    [ValidateRange(5, 300)][int]$MaxMinutes = 60,
    [switch]$Background,
    [switch]$CheckOnly,
    [switch]$Worker
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$Root = Join-Path $env:USERPROFILE 'workspace\research'
$LockPath = Join-Path $Root 'chrome.lock'
$Rules = Join-Path $env:USERPROFILE 'dotfiles\claude\workspaces\research\CLAUDE.md'
$PatrolHours = 8, 10, 12, 14, 16, 18, 20, 22, 24

# 巡回の時間帯 [偶数時-20分, 偶数時+30分) と [Start, End) が重なれば、その時間帯の終わりを返す。
function Get-PatrolConflictEnd([datetime]$Start, [datetime]$End) {
    for ($d = $Start.Date.AddDays(-1); $d -le $End.Date; $d = $d.AddDays(1)) {
        foreach ($h in $PatrolHours) {
            $t = $d.AddHours($h)
            $ws = $t.AddMinutes(-20); $we = $t.AddMinutes(30)
            if ($Start -lt $we -and $End -gt $ws) { return $we }
        }
    }
    return $null
}

function Get-NextStart([datetime]$From, [int]$Minutes) {
    $s = $From
    for ($i = 0; $i -lt 30; $i++) {
        $conflict = Get-PatrolConflictEnd $s $s.AddMinutes($Minutes)
        if ($null -eq $conflict) { return $s }
        $s = $conflict
    }
    return $null
}

# 使用中の印を読む。期限を過ぎていれば $null。
function Get-ActiveLock {
    if (!(Test-Path $LockPath)) { return $null }
    $text = Get-Content -Raw -Encoding utf8 $LockPath
    if ($text -match '(?m)^until:\s*(\S+)') {
        $until = [datetime]::Parse($Matches[1])
        if ($until -gt (Get-Date)) { return $text.Trim() }
    }
    return $null
}

function Write-Utf8([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

$now = Get-Date
# 印の期限は、打ち切りの時刻に後始末の5分を足したもの。
$until = $now.AddMinutes($MaxMinutes + 5)

if ($CheckOnly) {
    $next = Get-NextStart $now ($MaxMinutes + 5)
    $lock = Get-ActiveLock
    if ($null -eq $lock -and $next -eq $now) { Write-Output "ok: いま始められる（$MaxMinutes 分）" }
    else {
        if ($lock) { Write-Output "busy: Chrome を使用中`n$lock" }
        if ($next -ne $now) { Write-Output ("wait: 巡回の時間帯にかかる。次に始められる時刻 " + $(if ($next) { $next.ToString('yyyy-MM-dd HH:mm') } else { 'なし（0:30〜7:20 に短くして始める）' })) }
    }
    exit 0
}

if (-not $Dir) { throw '-Dir を指定する（C:\Users\kento\workspace\research\<YYYYMMDD>_<題名>）' }
$Dir = (Resolve-Path -LiteralPath $Dir).Path.TrimEnd('\')
if ((Split-Path $Dir -Parent) -ne $Root -or (Split-Path $Dir -Leaf) -notmatch '^\d{8}_\S+$') {
    throw "作業フォルダは $Root\<YYYYMMDD>_<題名> にする: $Dir"
}
$request = Join-Path $Dir "request_$N.md"
$report = Join-Path $Dir "report_$N.md"
$done = Join-Path $Dir "report_$N.done"
if (!(Test-Path $request)) { throw "request_$N.md が無い: $request" }

if (-not $Worker) {
    if ((Test-Path $done) -or (Test-Path $report)) {
        throw "report_$N はもうある。やり直すときは番号を上げる（request_$('{0:D2}' -f ([int]$N + 1)).md）"
    }
    if (-not $NoChrome) {
        $next = Get-NextStart $now ($MaxMinutes + 5)
        if ($next -ne $now) {
            $when = if ($next) { $next.ToString('yyyy-MM-dd HH:mm') } else { 'なし（-MaxMinutes を短くする）' }
            Write-Output "wait: ことねの巡回の時間帯にかかるので始めない。次に始められる時刻 $when"
            exit 3
        }
        $lock = Get-ActiveLock
        if ($lock) {
            Write-Output "busy: ほかの調査が Chrome を使っている`n$lock"
            exit 4
        }
        Write-Utf8 $LockPath "by: research`ndir: $Dir`nn: $N`nstart: $($now.ToString('s'))`nuntil: $($until.ToString('s'))`n"
    }

    if ($Background) {
        $argList = @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath, '-Dir', $Dir, '-N', $N, '-MaxMinutes', "$MaxMinutes", '-Worker')
        if ($NoChrome) { $argList += '-NoChrome' }
        try {
            Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $argList -WorkingDirectory $Dir -WindowStyle Hidden | Out-Null
        } catch {
            if (-not $NoChrome) { Remove-Item -LiteralPath $LockPath -ErrorAction SilentlyContinue }
            throw
        }
        Write-Output "started: report_$N.done ができるまで待つ（打ち切り $($now.AddMinutes($MaxMinutes).ToString('HH:mm'))）"
        exit 0
    }
}

# ここから本体（前で動かすときと、裏の -Worker）。
$deadline = $now.AddMinutes($MaxMinutes)
$chromeLine = if ($NoChrome) { 'Chrome は使わない（WebSearch と WebFetch で調べる）。' } else { 'ログイン中の Chrome（Claude in Chrome）を読むだけに使ってよい。' }
$prompt = @"
[Grok Bot / 依頼元: マーケター / 正本: $Rules / 書いてよい場所: $Dir]
このフォルダの request_$N.md を読み、調査して report_$N.md を書いてください。集めた資料は sources\ に置きます。$chromeLine
$($deadline.ToString('HH:mm')) に打ち切られます。その5分前までに report_$N.md を書き終えてください。
"@
$promptFile = Join-Path $Dir "prompt_$N.txt"
Write-Utf8 $promptFile $prompt
New-Item -ItemType Directory -Force -Path (Join-Path $Dir 'sources') | Out-Null

$tools = 'WebSearch,WebFetch,Read,Glob,Grep,Edit(./**)'
$chromeArgs = '--no-chrome'
if (-not $NoChrome) { $tools = "mcp__claude-in-chrome,$tools"; $chromeArgs = '--chrome' }
$cmd = "Get-Content -Raw -Encoding utf8 prompt_$N.txt | claude -p $chromeArgs --allowedTools '$tools' --output-format text > run_$N.log 2> run_$N.err; exit `$LASTEXITCODE"

$status = 'done 1'
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Get-Process -Id $PID).Path
    foreach ($a in @('-NoProfile', '-NonInteractive', '-Command', $cmd)) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Dir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    if ($proc.WaitForExit($MaxMinutes * 60 * 1000)) {
        $status = "done $($proc.ExitCode)"
    } else {
        $proc.Kill($true)
        $status = 'timeout'
    }
} catch {
    Write-Utf8 (Join-Path $Dir "run_$N.err") "$($_.Exception.Message)`n"
    $status = 'done 1'
} finally {
    if (-not $NoChrome) { Remove-Item -LiteralPath $LockPath -ErrorAction SilentlyContinue }
    $reportState = if (Test-Path $report) { 'report: あり' } else { 'report: なし' }
    # done は最後に書く（呼び出す側はこれを待つ）。
    Write-Utf8 $done "$status`n$reportState`nfinished: $((Get-Date).ToString('s'))`n"
}
if ($status -eq 'done 0') { exit 0 } else { exit 1 }
