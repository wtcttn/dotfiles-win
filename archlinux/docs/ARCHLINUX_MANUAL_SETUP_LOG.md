# archlinuxの操作メモ

wslのupdate

```sh
wsl --update --pre-release
```

## weztermの導入

```powershell
scoop bucket add versions
scoop install wezterm-nightly
```

[WezTerm セットアップガイド](WEZTERM_SETUP.md)

## archlinuxの初期化

[Install Arch Linux on WSL](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL)

```sh
pacman-key --init
pacman-key --populate
pacman -Syu
pacman -S base-devel git openssh vim wget curl sudo
useradd -m -G wheel -s /bin/bash kento
passwd kento
passwd
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
```

default userを設定

```sh
sudo vim /etc/wsl.conf
```

以下を追加

```toml
[user]
default = kento
```

system-loginの設定

```sh
sudo vim /etc/pam.d/system-login
```

以下を編集

```text
# - session optional pam_systemd.so から以下に変更
session optional pam_systemd.so
```

systemdでX11ソケットのシンボリックリンクを作成する設定を追加します。

```sh
sudo vim /etc/tmpfiles.d/wslg.conf
```

以下を追加

```
#      Path         Mode UID  GID  Age Argument
L+     %T/.X11-unix -    -    -    -   /mnt/wslg/.X11-unix
```

waylandのruntime-dirを設定

```sh
sudo vim /etc/profile.d/wslg.sh
```

以下を追加

```sh
export GALLIUM_DRIVER=d3d12
for i in "/mnt/wslg/runtime-dir/"*; do
  [ "$XDG_RUNTIME_DIR" = "$HOME" ] && XDG_RUNTIME_DIR="/var/run/user/$UID"
  if [ ! -L "$XDG_RUNTIME_DIR/$(basename "$i")" ]; then
    [ -d "$XDG_RUNTIME_DIR/$(basename "$i")" ] && rm -r "$XDG_RUNTIME_DIR/$(basename "$i")"
    ln -s "$i" "$XDG_RUNTIME_DIR/$(basename "$i")"
  fi
done
```

libeditのシンボリックリンクを作成

```sh
ln -s /usr/lib/libedit.so /usr/lib/libedit.so.2
```

## 言語環境の設定

```sh
sudo vim /etc/locale.gen
```

以下、コメントアウトを解除

```text
ja_JP.UTF-8 UTF-8
en_US.UTF-8 UTF-8
```

ロケールを生成

```sh
locale-gen
```

ロケールを設定

```sh
sudo vim /etc/locale.conf
```

以下を設定

```text
LANG=en_US.UTF-8
```

## zshの導入

```sh
sudo pacman -S zsh zsh-syntax-highlighting zsh-autosuggestions
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# プラグインの導入
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 以下はinstall.shで対応済みなので不要
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

## Dockerの導入

```sh
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER
newgrp docker
```

## pacmanで導入したパッケージ

```sh
# pacman-contribを導入
sudo pacman -S pacman-contrib
# ターミナルマルチプレクサ
sudo pacman -S tmux
# システム情報表示
sudo pacman -S screenfetch
# グラフィックスドライバ
sudo pacman -S mesa
# Vulkan対応
sudo pacman -S vulkan-dzn
# Vulkan対応
sudo pacman -S vulkan-icd-loader
# Vulkan対応
# sudo pacman -S lib32-vulkan-icd-loader
# クリップボード
sudo pacman -S wl-clipboard
# カレンダー
sudo pacman -S khal
# ファイル圧縮・解凍
sudo pacman -S p7zip
# ターミナルエミュレータ
sudo pacman -S ghostty
# Markdown viewer
sudo pacman -S glow
sudo pacman -S mdcat
# Geminiプロトコルクライアント
sudo pacman -S gemini-cli
# JSONパーサー
sudo pacman -S jq
# PDFビューア
sudo pacman -S poppler
# 画像表示ツール
sudo pacman -S chafa
# Azure CLI
sudo pacman -S azure-cli
```

## paruの導入

```sh
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

※ `install.sh` で対応済みなので不要

yayのAliasを設定 `~/.zshrc` に追加

```sh
alias yay='paru'
```

## paruで導入したパッケージ

```sh
# tmuxプラグインマネージャー
yay -S tmux-plugin-manager
# 時計
yay -S peaclock
# vdirsyncer
yay -S vdirsyncer
# vdirsyncerでgoogle calendarを使うために必要
yay -S python-aiohttp-oauthlib
# WSLg動作確認用
yay -S xorg-xeyes
# Windowsからssh-agentサービスをブリッジする
yay -S wsl2-ssh-agent
# Widnows HelloによるPAM認証
yay -S wsl-hello-sudo-bin
# version manager
yay -S proto-bin
# cursor cli
yay -S cursor-cli
# neovim
yay -S neovim-git
# AWS CLI
yay -S aws-cli-bin
# devpod
yay -S devpod-bin
# 画像表示ツール
yay -S imgcat
# Yazi (nightly)
yay -S yazi-nightly-bin
# ffmpeg
yay -S ffmpeg-git
# Discordクライアント
yay -S discordo-git
```

### wsl-hello-sudo-binのセットアップ

```sh
cd /opt/wsl-hello-sudo/
./install.sh
```

権限の関係でうまく行かないけど何とかする

`/etc/pam.d/sudo`を編集

```text
#%PAM-1.0
auth            sufficient      pam_wsl_hello.so
auth            include         system-auth
account         include         system-auth
session         include         system-auth
```

## tmuxの設定

### tmux-plugin-manager（TPM）のセットアップ

AURからインストールした場合、TPMは`/usr/share/tmux-plugin-manager`にインストールされます。

```sh
# プラグインディレクトリを作成
mkdir -p ~/.tmux/plugins

# TPMへのシンボリックリンクを作成
ln -s /usr/share/tmux-plugin-manager ~/.tmux/plugins/tpm
```

### tmux-resurrectの導入

`.tmux.conf`にプラグイン設定を追加後、以下を実行：

```sh
# tmux内でプレフィックスキー（Ctrl+g）を押してから Shift+i を押す
# または、tmuxを再起動
tmux kill-server
tmux
```

プラグインのインストール：

- **セッション保存**: `Ctrl+g` → `Ctrl+s`
- **セッション復元**: `Ctrl+g` → `Ctrl+r`

## vdirsyncerの設定

```sh
yay -S vdirsyncer
mkdir -p ~/.config/vdirsyncer
mkdir -p ~/.vdirsyncer/status
mkdir -p ~/.local/state/vdirsyncer
mkdir -p ~/.calendars/gcal/
touch ~/.config/vdirsyncer/config
```

以下のように設定ファイルを作成

```toml
[general]
status_path = "~/.vdirsyncer/status/"

[pair gcal]
a = "gcal_local"
b = "gcal_remote"
collections = ["from a", "from b"]
metadata = ["displayname"]

[storage gcal_local]
type = "filesystem"
path = "~/.calendars/gcal/"
fileext = ".ics"

[storage gcal_remote]
type = "google_calendar"
token_file = "~/.local/state/vdirsyncer/gcal_remote_token"
client_id = "GOOGLE_CLIENT_ID"
client_secret = "GOOGLE_CLIENT_SECRET"
```

設定の反映と同期

```sh
vdirsyncer discover
vdirsyncer sync
# vdirsyncerの定期実行を有効にする
systemctl --user enable vdirsyncer.timer
```

## khalの設定

```sh
mkdir -p ~/.config/khal
vim ~/.config/khal/config
```

以下のように設定ファイルを作成

```toml
[calendars]
[[gcal-cal]]
path = ~/.calendars/gcal/example@example.com

[[gcal-todo]]
path = ~/.calendars/gcal/xxxxxx@virtual

[locale]
local_timezone= Asia/Tokyo
default_timezone= Asia/Tokyo
timeformat= %H:%M
dateformat= %m-%d
longdateformat= %Y-%m-%d
datetimeformat= %m-%d %H:%M
longdatetimeformat= %Y-%m-%d %H:%M
```

## lazy nvimの導入

依存パッケージの導入

```sh
sudo pacman -S lua lua51 luarocks luajit tree-sitter tree-sitter-cli nodejs npm ripgrep fd lazygit fzf python-pynvim imagemagick ghostscript tectonic
sudo npm install -g neovim
sudo npm install -g @mermaid-js/mermaid-cli
```

```
:TSInstall css latex norg scss svelte typst vue
```

neorgのtreesitterのパーサーインストールエラー回避策

```sh
cd ~/.cache/nvim/tree-sitter-norg
cc -c -o parser.o src/parser.c -Isrc -shared -Os -std=c11
c++ -c -o scanner.o src/scanner.cc -Isrc -shared -Os -std=c++17
c++ -o parser.so parser.o scanner.o -lc -shared -Os
cp parser.so ~/.local/share/nvim/site/parser/norg.so
cd ~
rm -rf ~/.cache/nvim/tree-sitter-norg
```
