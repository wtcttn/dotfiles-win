# Dotfiles

WSL/Windows統合dotfiles管理。

## 構成

```
├── archlinux/          # Arch Linux の dotfiles と install.sh
├── windows/            # WezTerm、PowerShell、GlazeWM、Windows Neovim
├── wslc-dev/           # WSLc 共有開発コンテナ
├── macos/              # Mac の Ghostty、Neovim、AeroSpace、SketchyBar
└── grokbot/            # Grok Bot のボックスのスキルと install.sh
```

## 依存パッケージ

### WSL2 (Arch Linux)

- base-devel
- git
- curl
- wget
- openssh
- vim
- zsh
  - oh-my-zsh
  - powerlevel10k
- tmux
- screenfetch
- xdg-utils
- mesa
- vulkan-dzn
- vulkan-icd-loader

### Windows

- Oh My Posh
- WezTerm (推奨ターミナルエミュレータ)

## クイックスタート

**注意：** このリポジトリはWindows側（`C:\Users\kento\dotfiles\`）に配置されており、WSL環境からはシンボリックリンク（`~/dotfiles`）でアクセスします。

### WSL (Zsh + Powerlevel10k)
```bash
./archlinux/install.sh install
source ~/.zshrc
```

### PowerShell (Oh My Posh + custom theme)
> **前提:** シンボリックリンク作成を自動化するため、[Sudo for Windows](https://learn.microsoft.com/windows/sudo/) を有効化してから実行することを推奨します（または管理者権限でPowerShellを起動するか、開発者モードを有効にしてください）。

```powershell
winget install JanDeDobbeleer.OhMyPosh
.\windows\install-powershell.ps1 install  # Modules + Moralerspace font + WezTerm config
# GlazeWM のプロファイルを切り替えたい場合（例: ThinkPad）
# .\windows\install-powershell.ps1 install -GlazewmProfile thinkpad
```

**推奨:** WezTerm (半透過背景、Catppuccin Mocha、WSL Arch Linuxデフォルト)  
**Font:** Windows Terminal → `Moralerspace Neon HWJPDOC`

### macOS (Ghostty + Neovim + AeroSpace)

シェルは Powerlevel10k。Ghostty の見た目は、wslc-dev を開く Noctty に合わせる。ウィンドウは AeroSpace（GlazeWM のキー）、バーは SketchyBar（yume-bar）、枠は JankyBorders。パッケージは `macos/Brewfile`。

```bash
./macos/install.sh
```

Neovim は `wslc-dev/home/.config/nvim` のコピー。Obsidian のボルトは `~/notes`。プロンプトは `wslc-dev/home/.p10k.zsh` のコピー。Ghostty は Noctty の色と背景を使い、キー割り当ては macOS の既定にペイン移動を足したもの。初回は AeroSpace にアクセシビリティ権限を許可する。

### Grok Bot

Grok Bot のボックス（Linux）で使う。`cursor/skills/` を写したスキルを `grokbot/skills/` に置き、`/home/box/agent-data/workflows/<slug>/SKILL.md` へコピーする。ボルトは Syncthing で `/home/box/sync/obsidian-vault` に同期し、`~/notes` をそこへリンクする。Grok Bot が書くノートの `source` は `grok-bot`。

```bash
./grokbot/install.sh install   # ~/notes、スキル、Syncthing
./grokbot/install.sh convert   # cursor/skills のうち未変換のものだけ grokbot/skills へ写す
./grokbot/install.sh skills    # スキルだけ入れ直す
```

`cursor/skills/` を直したら、`grokbot/skills/<slug>` を消して `convert` し直す。

## 管理

```bash
# Sync
git pull && ./archlinux/install.sh install

# Update modules
./windows/install-powershell.ps1 install  # PowerShell
./archlinux/install.sh install            # Zsh

# Font reinstall
./windows/install-powershell.ps1 font

# WezTerm config reinstall
./windows/install-powershell.ps1 wezterm

# Noctty config（試用。アプリ本体は winget install AmanThanvi.noctty）
./windows/install-powershell.ps1 noctty

# Mutagen (Windows と WSLc ボリュームの同期) のインストール・設定
./windows/install-powershell.ps1 mutagen
```

## カスタマイズ

### Zsh (Powerlevel10k)
```bash
p10k configure  # Wizard
# or edit .p10k.zsh directly
```

### PowerShell (Oh My Posh)
```powershell
code $PROFILE  # Microsoft.PowerShell_profile.ps1
code C:\Users\kento\dotfiles\windows\ohmyposh-theme.omp.json
reload
```

### WezTerm
```powershell
code C:\Users\kento\.wezterm.lua         # User config (auto-installed)
code C:\Users\kento\dotfiles\windows\wezterm.lua  # Source config
```

## 設定詳細

**Zsh**: Oh My Zsh + Powerlevel10k (awesome-fontconfig mode)  
**PowerShell**: Oh My Posh (custom theme) + Terminal-Icons + posh-git  
**WezTerm**: Catppuccin Mocha + 半透過 (85%) + WSL Arch Linux デフォルト  
**Font**: Moralerspace HWJPDOC Nerd Font (auto-installed)

詳細: `windows/docs/POWERSHELL_SETUP.md`, `windows/docs/FONT_INSTALLATION_GUIDE.md`, `windows/docs/WEZTERM_SETUP.md`, `windows/docs/MUTAGEN_SETUP.md`（Windows と WSLc のボリュームの双方向同期、`scoop install mutagen`）