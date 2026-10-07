# PowerShell Setup

## インストール

> **前提:** シンボリックリンク作成のために [Sudo for Windows](https://learn.microsoft.com/windows/sudo/) を有効化しておくことを推奨します（または管理者権限でPowerShellを実行するか、開発者モードを有効化してください）。

```powershell
winget install JanDeDobbeleer.OhMyPosh
.\windows\install-powershell.ps1 install
# 端末に合わせて GlazeWM プロファイルを指定（例: ThinkPad 環境）
# .\windows\install-powershell.ps1 install -GlazewmProfile thinkpad
```

自動インストール：Terminal-Icons, posh-git, Moralerspace HWJPDOC

## 設定

**Theme:** `ohmyposh-theme.omp.json` (custom powerline)  
**Font:** `Moralerspace Neon HWJPDOC`

Windows Terminal: `Ctrl+,` → Font face → `Moralerspace Neon HWJPDOC`

## カスタマイズ

```powershell
code $PROFILE                                          # Profile
code C:\Users\kento\dotfiles\windows\ohmyposh-theme.omp.json  # Theme
reload                                                 # Apply
```

## コマンド

```powershell
# Profile
reload          # Reload profile
Edit-Profile    # Edit profile

# Git
gst             # git status

# Navigation
..              # cd ..
...             # cd ../..

# Aliases
ll              # Get-ChildItem
grep            # Select-String
which           # Get-Command
```

## モジュール

- **PSReadLine**: 予測入力、構文ハイライト、履歴検索
- **Terminal-Icons**: ファイル/フォルダアイコン
- **posh-git**: Git情報表示

## フォント再インストール

```powershell
.\windows\install-powershell.ps1 font
```

インストール先: `%LocalAppData%\Microsoft\Windows\Fonts` (管理者権限不要)

## リンク

- [Oh My Posh](https://ohmyposh.dev/)
- [Moralerspace](https://github.com/yuru7/moralerspace)
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons)
- [posh-git](https://github.com/dahlbyk/posh-git)
