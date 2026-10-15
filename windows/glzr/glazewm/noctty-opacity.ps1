# Noctty の透過を GlazeWM のフォーカス効果から守る。
#
# Noctty の background-opacity はウィンドウ全体の不透明度（layered window の alpha）で実装されている。
# GlazeWM は focused_window.transparency が無効でも other_windows.transparency が有効だと、
# フォーカスした窓の alpha を 255 に戻すので、Noctty の透過が消える。ウィンドウごとに除外する設定は無く、
# window_rules の on: focus も GlazeWM 自身のフォーカス移動（alt+矢印など）では走らない。
# そこで focus_changed を購読し、Noctty にフォーカスが移るたびに Noctty の値を当て直す。
#
# GlazeWM の startup_commands から起動する。設定の再読み込みなどで購読が切れたら購読し直し、
# GlazeWM のプロセスが無くなったら終わる。

$ErrorActionPreference = "Continue"
$NocttyConfig = Join-Path $PSScriptRoot "..\..\noctty\config.ghostty"

# 設定の再読み込みで二重に起動されても、先にいる方が購読を続ける。
$script:mutex = New-Object System.Threading.Mutex($false, "Local\NocttyOpacityWatcher")
try {
    $owned = $script:mutex.WaitOne(0)
}
catch [System.Threading.AbandonedMutexException] {
    $owned = $true
}
if (-not $owned) {
    exit 0
}

function Get-NocttyOpacity {
    $line = Select-String -LiteralPath $NocttyConfig -Pattern '^\s*background-opacity\s*=\s*([0-9.]+)' |
        Select-Object -Last 1
    if (-not $line) {
        return $null
    }
    return [double]$line.Matches[0].Groups[1].Value
}

function Set-NocttyOpacity($id) {
    $opacity = Get-NocttyOpacity
    if ($null -eq $opacity -or $opacity -ge 1 -or [string]::IsNullOrEmpty($id)) {
        return
    }
    # フォーカス効果の適用がイベントより後になることがあるので、少し待ってから当てる。
    Start-Sleep -Milliseconds 150
    & glazewm command --id $id set-transparency --opacity "$([math]::Round($opacity * 100))%" | Out-Null
}

# 起動した時点で前面にある Noctty も戻す。次のフォーカスまで待たない。
try {
    $focused = (& glazewm query focused 2>$null | ConvertFrom-Json).data.focused
    if ($focused.type -eq "window" -and $focused.processName -eq "noctty") {
        Set-NocttyOpacity $focused.id
    }
}
catch {
}

while (Get-Process glazewm -ErrorAction SilentlyContinue) {
    & glazewm sub --events focus_changed 2>$null | ForEach-Object {
        try {
            $container = ($_ | ConvertFrom-Json).data.focusedContainer
        }
        catch {
            return
        }
        if ($container.type -ne "window" -or $container.processName -ne "noctty") {
            return
        }
        Set-NocttyOpacity $container.id
    }
    Start-Sleep -Seconds 2
}
