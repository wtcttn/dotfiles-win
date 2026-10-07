# WSLc 上の共有開発コンテナを管理する。
# 既存の dotfiles（.zshrc や .config/nvim）は参照しない。
#
#   .\wslc-dev\dev.ps1 build      イメージを作る
#   .\wslc-dev\dev.ps1 up         コンテナを起動する
#   .\wslc-dev\dev.ps1 enter      zsh に入る（止まっていれば起動する）
#   .\wslc-dev\dev.ps1 nvim       Neovim を開く
#   .\wslc-dev\dev.ps1 down       コンテナを止める
#   .\wslc-dev\dev.ps1 recreate   コンテナだけ作り直す（ホームボリュームは残す）
#   .\wslc-dev\dev.ps1 status     状態を表示する

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("build", "up", "enter", "nvim", "down", "recreate", "status")]
    [string]$Command = "status",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$ArgsRest
)

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$Image = "wslc-dev:local"
$Container = "wslc-dev"
$Volume = "wslc-dev-home"
$Workspace = "C:\Users\kento\workspace"
$WindowsSsh = "C:\Users\kento\.ssh"
$HomeConfig = Join-Path $Root "home"

function ConvertTo-WslcPath {
    param([string]$Path)
    return ([System.IO.Path]::GetFullPath($Path) -replace '\\', '/')
}

function Invoke-Wslc {
    param([Parameter(Mandatory = $true)][string[]]$WslcArgs)
    & wslc @WslcArgs
    if ($LASTEXITCODE -ne 0) {
        throw "wslc $($WslcArgs -join ' ') が失敗しました (exit $LASTEXITCODE)"
    }
}

function Read-WslcJsonLines {
    param([string[]]$Lines)
    foreach ($line in $Lines) {
        $text = "$line".Trim()
        if (-not $text.StartsWith("{")) {
            continue
        }
        try {
            $text | ConvertFrom-Json
        }
        catch {
            continue
        }
    }
}

function Get-WslcContainerStatus {
    $lines = & wslc list -a --format json 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    $match = Read-WslcJsonLines $lines | Where-Object { $_.Names -eq $Container } | Select-Object -First 1
    if (-not $match) {
        return $null
    }
    return "$($match.State)".Trim()
}

function Test-WslcContainer {
    return [bool](Get-WslcContainerStatus)
}

function Ensure-Workspace {
    if (-not (Test-Path -LiteralPath $Workspace)) {
        New-Item -ItemType Directory -Path $Workspace | Out-Null
        Write-Host "作成しました: $Workspace"
    }
}

function Ensure-Volume {
    $lines = & wslc volume list --format json 2>$null
    if ($LASTEXITCODE -eq 0) {
        $exists = Read-WslcJsonLines $lines | Where-Object { $_.Name -eq $Volume } | Select-Object -First 1
        if ($exists) {
            return
        }
    }
    Write-Host "ボリュームを作成します: $Volume"
    # 動的 VHD。中身は Linux の ext4 で、Neovim のデータと zsh の履歴を置く。
    Invoke-Wslc @(
        "volume", "create",
        "--driver", "vhd",
        "--opt", "SizeBytes=21474836480",
        "--opt", "Uid=1000",
        "--opt", "Gid=1000",
        $Volume
    )
}

function Start-DevContainer {
    Ensure-Workspace
    Ensure-Volume

    $status = Get-WslcContainerStatus
    if ($status -eq "running") {
        Write-Host "起動済みです: $Container"
        return
    }
    if ($status) {
        Write-Host "起動します: $Container ($status)"
        Invoke-Wslc @("start", $Container)
        return
    }

    Write-Host "コンテナを作成します: $Container"
    Invoke-Wslc @(
        "run", "--detach", "--name", $Container,
        "-v", "$(ConvertTo-WslcPath $Workspace):/workspace",
        "-v", "$(ConvertTo-WslcPath $HomeConfig):/opt/wslc-dev/home",
        "-v", "$(ConvertTo-WslcPath $WindowsSsh):/mnt/win-ssh:ro",
        "-v", "${Volume}:/home/kento",
        "-w", "/workspace",
        $Image
    )
}

switch ($Command) {
    "build" {
        Invoke-Wslc @(
            "build", "-t", $Image,
            "-f", (ConvertTo-WslcPath (Join-Path $Root "Dockerfile")),
            (ConvertTo-WslcPath $Root)
        )
        Write-Host "イメージを作成しました: $Image"
    }
    "up" {
        Start-DevContainer
    }
    "down" {
        if (-not (Test-WslcContainer)) {
            Write-Host "コンテナはありません: $Container"
            break
        }
        Invoke-Wslc @("stop", $Container)
        Write-Host "停止しました: $Container"
    }
    "recreate" {
        if (Test-WslcContainer) {
            Invoke-Wslc @("stop", $Container)
            Invoke-Wslc @("remove", $Container)
        }
        Start-DevContainer
    }
    "enter" {
        Start-DevContainer
        & wslc exec -it -u kento -w /workspace $Container zsh
        exit $LASTEXITCODE
    }
    "nvim" {
        Start-DevContainer
        & wslc exec -it -u kento -w /workspace $Container nvim @ArgsRest
        exit $LASTEXITCODE
    }
    "status" {
        Write-Host "image:     $Image"
        Write-Host "container: $Container"
        Write-Host "volume:    $Volume"
        Write-Host "workspace: $Workspace"
        $status = Get-WslcContainerStatus
        if ($status) {
            Write-Host "state:     $status"
        }
        else {
            Write-Host "state:     absent"
        }
    }
}
