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
#   .\wslc-dev\dev.ps1 packages-save     コンテナに入れたパッケージの一覧を home/packages/ に書き出す
#   .\wslc-dev\dev.ps1 packages-restore  home/packages/ の一覧からパッケージを入れ直す（recreate の後に使う）

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("build", "up", "enter", "nvim", "down", "recreate", "status", "packages-save", "packages-restore")]
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

# 追加のボリューム（ボリューム名 => コンテナ内のパス）。リポジトリの node_modules など、
# Windows 側（VirtioFS）に置くと遅いものを重ねるのに使う。マシンやプロジェクトに固有の値なので、
# git で管理しない dev.local.ps1 に書く（書式は dev.local.example.ps1）。
# 追加・変更したら recreate する（マウントはコンテナ作成時に固定される）。
$ExtraVolumes = [ordered]@{}
$LocalConfig = Join-Path $Root "dev.local.ps1"
if (Test-Path -LiteralPath $LocalConfig) {
    . $LocalConfig
}

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

function New-UserVolume {
    param([string]$Name, [string]$SizeBytes)
    $lines = & wslc volume list --format json 2>$null
    if ($LASTEXITCODE -eq 0) {
        $exists = Read-WslcJsonLines $lines | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
        if ($exists) {
            return
        }
    }
    Write-Host "ボリュームを作成します: $Name"
    # 動的 VHD。中身は Linux の ext4 で、所有者を kento (1000) にする。
    Invoke-Wslc @(
        "volume", "create",
        "--driver", "vhd",
        "--opt", "SizeBytes=$SizeBytes",
        "--opt", "Uid=1000",
        "--opt", "Gid=1000",
        $Name
    )
}

function Ensure-Volume {
    # ホーム: Neovim のデータ、zsh の履歴、proto のツール (~/.proto)、gem を置く。
    New-UserVolume $Volume "21474836480"
    foreach ($name in $ExtraVolumes.Keys) {
        New-UserVolume $name "10737418240"
    }
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
    $runArgs = @(
        "run", "--detach", "--name", $Container,
        "-v", "$(ConvertTo-WslcPath $Workspace):/workspace",
        "-v", "$(ConvertTo-WslcPath $HomeConfig):/opt/wslc-dev/home",
        "-v", "$(ConvertTo-WslcPath $WindowsSsh):/mnt/win-ssh:ro",
        "-v", "${Volume}:/home/kento"
    )
    foreach ($name in $ExtraVolumes.Keys) {
        $runArgs += @("-v", "${name}:$($ExtraVolumes[$name])")
    }
    $runArgs += @("-w", "/workspace", $Image)
    Invoke-Wslc $runArgs
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
    "packages-save" {
        Start-DevContainer
        # 公式 (pacman -Qqen)、AUR (pacman -Qqem)、proto のツールとバージョン、proto のグローバル設定
        $script = @'
set -e
dir=/opt/wslc-dev/home/packages
mkdir -p "$dir"
pacman -Qqen > "$dir/pacman.txt"
pacman -Qqem | grep -v -- '-debug$' > "$dir/aur.txt"
: > "$dir/proto.txt"
for d in "$HOME"/.proto/tools/*/*/; do
  tool=$(basename "$(dirname "$d")"); ver=$(basename "$d")
  case "$ver" in *[0-9]*) echo "$tool $ver" >> "$dir/proto.txt" ;; esac
done
sort -o "$dir/proto.txt" "$dir/proto.txt"
cp "$HOME/.proto/.prototools" "$dir/prototools.toml" 2>/dev/null || true
wc -l "$dir"/*.txt
'@
        # Windows PowerShell 5.1 は引数の " を正しく渡せないので、スクリプトは標準入力で渡す（CRLF は LF にする）
        # 5.1 の既定 $OutputEncoding は ASCII で、パイプの末尾に CRLF が付く。BOM 無し UTF-8 にし、最後の行をコメントにして CR を無害にする
        $OutputEncoding = New-Object System.Text.UTF8Encoding $false
        (($script -replace "`r", "") + "`n# end") | & wslc exec -i -u kento $Container zsh -s
        exit $LASTEXITCODE
    }
    "packages-restore" {
        Start-DevContainer
        $script = @'
set -e
dir=/opt/wslc-dev/home/packages
[ -f "$dir/pacman.txt" ] && sudo pacman -S --needed --noconfirm - < "$dir/pacman.txt"
[ -s "$dir/aur.txt" ] && paru -S --needed --noconfirm - < "$dir/aur.txt"
[ -f "$dir/prototools.toml" ] && cp "$dir/prototools.toml" "$HOME/.proto/.prototools"
if [ -f "$dir/proto.txt" ]; then
  # pnpm 等は node が要るので node を先に入れる
  grep '^node ' "$dir/proto.txt" | while read -r tool ver; do proto install "$tool" "$ver"; done
  grep -v '^node ' "$dir/proto.txt" | while read -r tool ver; do proto install "$tool" "$ver"; done
fi
'@
        # Windows PowerShell 5.1 は引数の " を正しく渡せないので、スクリプトは標準入力で渡す（CRLF は LF にする）
        # 5.1 の既定 $OutputEncoding は ASCII で、パイプの末尾に CRLF が付く。BOM 無し UTF-8 にし、最後の行をコメントにして CR を無害にする
        $OutputEncoding = New-Object System.Text.UTF8Encoding $false
        (($script -replace "`r", "") + "`n# end") | & wslc exec -i -u kento $Container zsh -s
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
