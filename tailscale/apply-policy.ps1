<#
.SYNOPSIS
  tailscale/policy.hujson を tailnet のポリシー（ACL）に反映する。

.DESCRIPTION
  1. tailscale/secrets.bw に従って、Bitwarden から API の鍵と印の値を読む（値は画面に出さない）。
  2. policy.hujson の ${名前} を埋め、Tailscale の検証 API で確かめる。
  3. 今のポリシーとの差分を、印の値を伏せて表示する。
  4. -Apply を付けたときだけ送る。読んだときから管理画面で直されていたら（ETag が違えば）送らずに止まる。

.EXAMPLE
  ./tailscale/apply-policy.ps1          # 確かめるだけ
  ./tailscale/apply-policy.ps1 -Apply   # 送る
#>
param([switch]$Apply)

$ErrorActionPreference = "Stop"
$api = "https://api.tailscale.com/api/v2"
$here = $PSScriptRoot

# --- Bitwarden から値を読む ---
if ((bw status | ConvertFrom-Json).status -eq "unauthenticated") {
    throw "Bitwarden にログインしていません。先に bw login を実行してください。"
}
$session = $env:BW_SESSION
if (!$session -or (bw status --session $session | ConvertFrom-Json).status -ne "unlocked") {
    $session = if (Get-Command Get-BwSession -ErrorAction SilentlyContinue) { Get-BwSession } else { bw unlock --raw }
}
if (!$session) { throw "Bitwarden の解錠に失敗しました。" }
bw sync --session $session | Out-Null

$values = @{}
foreach ($line in Get-Content (Join-Path $here "secrets.bw")) {
    $l = $line.Trim()
    if (!$l -or $l.StartsWith("#")) { continue }
    $name, $ref = $l.Split("=", 2) | ForEach-Object { $_.Trim() }
    $item, $field = $ref.Split(":", 2)
    if (!$field) { $field = "password" }
    $value = bw get $field $item --session $session 2>$null
    if (!$value) { throw "Bitwarden の項目 $item の $field 欄が読めません（$name）。" }
    $values[$name] = $value
}

# --- 印を埋める ---
$template = Get-Content -Raw (Join-Path $here "policy.hujson")
$marks = @([regex]::Matches($template, '\$\{([A-Z0-9_]+)\}') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
foreach ($k in $marks) {
    if (!$values.ContainsKey($k)) { throw "印 `${$k} の値が secrets.bw にありません。" }
}
$policy = $template
foreach ($k in $marks) { $policy = $policy.Replace("`${$k}", $values[$k]) }
$body = [System.Text.Encoding]::UTF8.GetBytes($policy)

# 画面に出す前に、印の値を印に戻す
function Hide([string]$s) {
    foreach ($k in $marks) { $s = $s.Replace($values[$k], "`${$k}") }
    return $s
}

# --- API ---
$token = Invoke-RestMethod -Method Post -Uri "$api/oauth/token" -Body @{
    client_id     = $values["TS_OAUTH_CLIENT_ID"]
    client_secret = $values["TS_OAUTH_CLIENT_SECRET"]
}
$auth = @{ Authorization = "Bearer $($token.access_token)" }

$current = Invoke-WebRequest -Uri "$api/tailnet/-/acl" -Headers ($auth + @{ Accept = "application/hujson" })
$etag = @($current.Headers["ETag"])[0]
$currentText = if ($current.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($current.Content) } else { [string]$current.Content }

$check = Invoke-RestMethod -Method Post -Uri "$api/tailnet/-/acl/validate" -Headers $auth `
    -ContentType "application/hujson" -Body $body
if ($check.message) {
    Write-Host "検証で止まりました: $(Hide $check.message)" -ForegroundColor Red
    if ($check.data) { Write-Host (Hide ($check.data | ConvertTo-Json -Depth 6)) }
    exit 1
}
Write-Host "検証: 問題なし" -ForegroundColor Green

# --- 差分（印の値は伏せる） ---
$old = (Hide $currentText) -split "`r?`n"
$new = (Hide $policy) -split "`r?`n"
$diff = Compare-Object $old $new
if (!$diff) {
    Write-Host "今のポリシーと同じです。送るものはありません。" -ForegroundColor Green
    exit 0
}
Write-Host "差分（- 今のポリシー / + policy.hujson）:" -ForegroundColor Cyan
foreach ($d in $diff) {
    $mark = if ($d.SideIndicator -eq "<=") { "-" } else { "+" }
    $color = if ($mark -eq "-") { "Red" } else { "Green" }
    Write-Host "$mark $($d.InputObject)" -ForegroundColor $color
}

if (!$Apply) {
    Write-Host "確かめただけです。送るときは -Apply を付けて実行してください。" -ForegroundColor Yellow
    exit 0
}

Invoke-RestMethod -Method Post -Uri "$api/tailnet/-/acl" -Headers ($auth + @{ "If-Match" = $etag }) `
    -ContentType "application/hujson" -Body $body | Out-Null
Write-Host "ポリシーを反映しました。" -ForegroundColor Green
