<#
.SYNOPSIS
調査の作業フォルダで Claude Code（claude -p）を動かす。Grok Bot のマーケターが PC で呼ぶ。

.DESCRIPTION
取り決めの正本は dotfiles の grokbot/claude-code.md の「調査を直接呼ぶ」。
作業フォルダ（C:\Users\kento\workspace\research\<YYYYMMDD>_<題名>\）の request_NN.md を読ませ、
report_NN.md と sources\ を書かせる。終わったら report_NN.done を書く（1行目が done <終了コード>、timeout、abandoned のどれか）。
Chrome を使うとき（既定）も、ことねの巡回と並列で動かしてよい（2026-11-12 オーナー決定）。

Chrome の後始末: 会話の ID を先に決め（session_NN.txt）、終わったら正常終了でも打ち切りでも同じ会話を再開して、
その会話のタブグループのタブをすべて閉じる（最後のタブを閉じると、グループも「保存したタブグループ」から消える）。
このスクリプト自体が外から止められて後始末できなかった調査は、次にこのスクリプトを起動したときに片付ける（abandoned）。

.EXAMPLE
& C:\Users\kento\dotfiles\claude\workspaces\research\run-research.ps1 -Dir C:\Users\kento\workspace\research\20261112_shorts_trend -N 01 -Background
  裏で動かしてすぐ戻る。report_01.done ができるまで待つ。
#>
[CmdletBinding()]
param(
    [string]$Dir,
    [ValidatePattern('^\d{2}$')][string]$N = '01',
    [switch]$NoChrome,
    [ValidateRange(5, 300)][int]$MaxMinutes = 60,
    [switch]$Background,
    [switch]$Worker
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$Root = Join-Path $env:USERPROFILE 'workspace\research'
$Rules = Join-Path $env:USERPROFILE 'dotfiles\claude\workspaces\research\CLAUDE.md'
# 後始末（会話を再開してタブを閉じる）の上限。ふだんは 10 秒ほどで終わる。
$CleanupSeconds = 90

function Write-Utf8([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

# pwsh -Command を、待つ時間を決めて動かす。時間切れなら子のプロセスごと止めて $null を返す。
function Invoke-Timed([string]$Command, [int]$Seconds, [string]$WorkDir) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Get-Process -Id $PID).Path
    foreach ($a in @('-NoProfile', '-NonInteractive', '-Command', $Command)) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    if ($proc.WaitForExit($Seconds * 1000)) { return $proc.ExitCode }
    $proc.Kill($true)
    return $null
}

# 同じ会話を再開し、その会話のタブグループに残ったタブをすべて閉じる。見えるのはその会話のグループだけなので、
# ことねの巡回やオーナーのタブ、ほかの調査のグループには届かない。done に書く tabs: の行を返す。
function Invoke-ChromeCleanup([string]$WorkDir, [string]$Num, [string]$SessionId) {
    $cleanupPrompt = 'run-research.ps1 の後始末です。ページは開かず、ほかのことはしないでください。tabs_context_mcp を createIfEmpty なしで呼び、この会話のタブグループに残っているタブをすべて tabs_close_mcp で閉じてください。そのあと tabs_context_mcp をもう一度呼び、最後に「tabs-before: <閉じる前の数> tabs-after: <閉じた後の数>」の1行だけを返してください。グループが無ければ数は 0 です。'
    Write-Utf8 (Join-Path $WorkDir "cleanup_$Num.txt") $cleanupPrompt
    $cleanupCmd = "Get-Content -Raw -Encoding utf8 cleanup_$Num.txt | claude -p --resume $SessionId --chrome --allowedTools 'mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_close_mcp' --output-format text > cleanup_$Num.log 2>&1; exit `$LASTEXITCODE"
    try {
        $null = Invoke-Timed $cleanupCmd $CleanupSeconds $WorkDir
        $line = Get-Content -Encoding utf8 -LiteralPath (Join-Path $WorkDir "cleanup_$Num.log") -ErrorAction SilentlyContinue | Select-String 'tabs-before:\s*\d+\s+tabs-after:\s*\d+' | Select-Object -Last 1
        if ($line) { return "tabs: $($line.Matches[0].Value)" }
        return "tabs: 後始末を確かめられない（cleanup_$Num.log を見る）"
    } catch {
        return "tabs: 後始末に失敗（$($_.Exception.Message)）"
    }
}

# 前に外から止められて、done を書けずに終わった調査を片付ける。session_NN.txt があり、done が無く、
# 書いてある pid の pwsh がもういないものだけ。Chrome を使っていれば後始末をして、done を abandoned で書く。
function Clear-AbandonedRuns {
    foreach ($s in @(Get-ChildItem -Path $Root -Filter 'session_*.txt' -Recurse -Depth 1 -ErrorAction SilentlyContinue)) {
        if ($s.Name -notmatch '^session_(\d{2})\.txt$') { continue }
        $num = $Matches[1]
        $wd = $s.DirectoryName
        if (Test-Path (Join-Path $wd "report_$num.done")) { continue }
        $info = @{}
        foreach ($l in Get-Content -Encoding utf8 -LiteralPath $s.FullName) { if ($l -match '^(\w+):\s*(.*)$') { $info[$Matches[1]] = $Matches[2].Trim() } }
        if (-not $info.session -or -not $info.pid) { continue }
        $p = Get-Process -Id ([int]$info.pid) -ErrorAction SilentlyContinue
        if ($p -and $p.StartTime.ToString('s') -eq $info.started) { continue }  # まだ動いている
        $tabs = if ($info.chrome -eq 'yes') { Invoke-ChromeCleanup $wd $num $info.session } else { 'tabs: Chrome を使っていない' }
        $reportState = if (Test-Path (Join-Path $wd "report_$num.md")) { 'report: あり' } else { 'report: なし' }
        Write-Utf8 (Join-Path $wd "report_$num.done") "abandoned`n$reportState`n$tabs`nsession: $($info.session)`nfinished: $((Get-Date).ToString('s'))`n"
        Write-Output "cleaned: 前に止まった調査 $wd の $num を片付けた（$tabs）"
    }
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

$now = Get-Date
if (-not $Worker) {
    if ((Test-Path $done) -or (Test-Path $report) -or (Test-Path (Join-Path $Dir "session_$N.txt"))) {
        throw "report_$N はもうある。やり直すときは番号を上げる（request_$('{0:D2}' -f ([int]$N + 1)).md）"
    }
    Clear-AbandonedRuns
    if ($Background) {
        $argList = @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath, '-Dir', $Dir, '-N', $N, '-MaxMinutes', "$MaxMinutes", '-Worker')
        if ($NoChrome) { $argList += '-NoChrome' }
        Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $argList -WorkingDirectory $Dir -WindowStyle Hidden | Out-Null
        Write-Output "started: report_$N.done ができるまで待つ（打ち切り $($now.AddMinutes($MaxMinutes).ToString('HH:mm'))）"
        exit 0
    }
}

# ここから本体（前で動かすときと、裏の -Worker）。
$deadline = $now.AddMinutes($MaxMinutes)
# 会話の ID を決めておく。Chrome のタブグループはこの会話のものなので、後始末で同じ会話を再開して閉じる。
# 外から止められたときに次の起動で片付けられるよう、ID と、このプロセスの pid・起動時刻を session_NN.txt に残す。
$sessionId = [guid]::NewGuid().ToString()
$self = Get-Process -Id $PID
Write-Utf8 (Join-Path $Dir "session_$N.txt") "session: $sessionId`npid: $PID`nstarted: $($self.StartTime.ToString('s'))`nchrome: $(if ($NoChrome) { 'no' } else { 'yes' })`n"
$chromeLine = if ($NoChrome) { 'Chrome は使わない（WebSearch と WebFetch で調べる）。' } else { 'ログイン中の Chrome（Claude in Chrome）を読むだけに使ってよい。tabs_context_mcp（createIfEmpty: true）で作られる空のタブを使い、終わる前にこの調査のタブグループのタブをすべて閉じる（最初の空のタブも）。' }
$prompt = @"
[Grok Bot / 依頼元: マーケター / 正本: $Rules / 書いてよい場所: $Dir]
このフォルダの request_$N.md を読み、調査して report_$N.md を書いてください。集めた資料は sources\ に置きます。$chromeLine
$($deadline.ToString('HH:mm')) に打ち切られます。その5分前までに report_$N.md を書き終えてください。
"@
Write-Utf8 (Join-Path $Dir "prompt_$N.txt") $prompt
New-Item -ItemType Directory -Force -Path (Join-Path $Dir 'sources') | Out-Null

$tools = 'WebSearch,WebFetch,Read,Glob,Grep,Edit(./**)'
$chromeArgs = '--no-chrome'
if (-not $NoChrome) { $tools = "mcp__claude-in-chrome,$tools"; $chromeArgs = '--chrome' }
$cmd = "Get-Content -Raw -Encoding utf8 prompt_$N.txt | claude -p --session-id $sessionId $chromeArgs --allowedTools '$tools' --output-format text > run_$N.log 2> run_$N.err; exit `$LASTEXITCODE"

$status = 'done 1'
$tabs = 'tabs: Chrome を使っていない'
try {
    $code = Invoke-Timed $cmd ($MaxMinutes * 60) $Dir
    $status = if ($null -eq $code) { 'timeout' } else { "done $code" }
} catch {
    Add-Content -Encoding utf8 -LiteralPath (Join-Path $Dir "run_$N.err") "$($_.Exception.Message)"
    $status = 'done 1'
} finally {
    # 後始末は、正常終了でも打ち切りでも動かす。
    if (-not $NoChrome) { $tabs = Invoke-ChromeCleanup $Dir $N $sessionId }
    $reportState = if (Test-Path $report) { 'report: あり' } else { 'report: なし' }
    # done は最後に書く（呼び出す側はこれを待つ）。
    Write-Utf8 $done "$status`n$reportState`n$tabs`nsession: $sessionId`nfinished: $((Get-Date).ToString('s'))`n"
}
if ($status -eq 'done 0') { exit 0 } else { exit 1 }
