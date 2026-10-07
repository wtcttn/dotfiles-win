# WSLc 開発環境

このファイルが、Claude、Codex、Cursor で共有する運用方針である。実装は `wslc-dev/` にある。方針と実装が食い違ったら実装を正とし、このファイルを合わせる。

## 役割

- 日常のシェルと、開発リポジトリを開く Neovim は、WSLc の共有コンテナ `wslc-dev`（イメージ `wslc-dev:local`）である。
- 開発リポジトリは `C:\Users\kento\workspace\{org}\{repo}` に置く。コンテナ内では `/workspace`。
- プロジェクト用ランタイムのコンテナに nvim と zsh は入れない。言語サーバーは共有コンテナの中で動かす。
- Windows の nvim は、このコンテナに載せていないファイル用である。開発リポジトリはコンテナの nvim で開く。
- WSL2 の Arch は、systemd、WSLg、fcitx、vdirsyncer が必要なときだけ残す。日常のシェルにはしない。
- ランタイムは `wslc.exe` である。DevPod と、Arch 内の Docker は使わない。

## 変更してよい場所

コンテナ環境の変更は `wslc-dev/` に閉じる。WezTerm の既定端末だけ、`windows/wezterm.lua` にある `default_prog` と launch menu の WSLc 項目を触る。

次は、その作業を明示されなければ変更しない。

- `archlinux/` の Arch 用 dotfiles（`.zshrc`、`.zshenv`、`.p10k.zsh`、`.config/nvim` など）
- Arch の nvim アンインストールと、`~/.config/nvim` シンボリックリンクの削除
- 既存の WSLc スタック。コンテナは web、nginx、sidekiq、api、floci-ui、floci、valkey、postgresql。ネットワークは `myfans`。ボリュームは `mf_*`。パスは `C:\Users\kento\workspace\getozinc\`

## レイアウト

| 名前 | 実体 | コンテナ内 |
| --- | --- | --- |
| イメージ `wslc-dev:local` | `wslc-dev/Dockerfile` | |
| コンテナ `wslc-dev` | `wslc-dev/dev.ps1` が作成 | |
| ボリューム `wslc-dev-home` | 動的 VHD、20GiB、uid/gid 1000 | `/home/kento` |
| ワークスペース | `C:\Users\kento\workspace` | `/workspace` |
| 設定 | `wslc-dev/home` | `/opt/wslc-dev/home` |
| Windows SSH | `C:\Users\kento\.ssh`（読み取り専用） | `/mnt/win-ssh` |

ユーザーは `kento`、uid/gid 1000。sudo は NOPASSWD。

起動時、`wslc-dev/home` の `.zshenv`、`.zshrc`、`.p10k.zsh`、`.gitconfig`、`.config/nvim` をホームへシンボリックリンクする。宛先が無い、または既にシンボリックリンクのときだけ張り替える。ホームボリューム上の実ファイルは残す。

## 操作

管理コマンドは `wslc-dev/dev.ps1`。Windows PowerShell 5.1 で動かす。`dev.ps1` は UTF-8 BOM。`entrypoint.sh` は LF。

- `build` はイメージを作る。
- `up` はコンテナを起動する。無ければ作成する。
- `enter` はユーザー `kento` の zsh に入る。
- `nvim` はコンテナの nvim を開く。
- `down` はコンテナを止める。
- `recreate` はコンテナだけ作り直す。ホームボリュームは残る。イメージ由来の書き込み層は消える。
- `status` は状態を表示する。

マウントはコンテナ作成時に固定される。`up` と `start` では新しい `-v` は付かない。Dockerfile と entrypoint を変えたあとは `build` してから `recreate` する。

`wslc list` と `wslc volume list` の `--format json` は NDJSON である。`inspect --format` は JSON であり、Go テンプレートではない。

`dev.ps1` では、関数引数に `-d` を渡さない。PowerShell が `-Debug` に取る。継続行の先頭を `--opt` にしない。`wslc` への引数は文字列配列で `Invoke-Wslc` に渡す。

WezTerm の既定は `wslc-dev/wezterm.cmd` である。`wslc start wslc-dev` のあと `wslc exec -it -u kento -w /workspace wslc-dev zsh` を実行する。反映には新しいウィンドウが要る。Arch はランチャに残す。

## パッケージ

イメージに残る定義は Dockerfile である。公式パッケージの `pacman -S`、`/usr/bin` の proto、AUR の `paru` を `makepkg -si` で入れる箇所が、Brewfile に相当する。

同じコンテナを使い続けるあいだの更新は、コンテナの中で `paru -Syu` する。`down` して `up` しても残る。`recreate` すると消えるので、残したいパッケージは Dockerfile に足して rebuild する。

`pacman -Syu` だけにはしない。libalpm の soname が上がると paru が動かなくなる。`paru-bin` は入れない。イメージの pacman は `libalpm.so.16` で、paru は AUR の `paru` をソースからビルドする。

Oh My Zsh、Powerlevel10k、zsh-autosuggestions、zsh-syntax-highlighting は pacman パッケージではない。`/usr/share/oh-my-zsh` への git clone である。`zstyle ':omz:update' mode disabled`。これらの更新をイメージに残すときも Dockerfile を rebuild する。

走っているコンテナの明示インストールを控えるときは、次で公式と AUR を分ける。

```bash
pacman -Qqen > pkglist.txt
pacman -Qqem > aurlist.txt
```

戻すときは `sudo pacman -S --needed - < pkglist.txt` と `paru -S --needed - < aurlist.txt`。この一覧をイメージの定義にはしない。

proto のバイナリは `/usr/bin/proto` と `/usr/bin/proto-shim`。ツール本体はホームボリュームの `~/.proto` に入る。ツールの一覧は `~/.proto/.prototools`。zsh は `PROTO_HOME=$HOME/.proto` と `PROTO_LOOKUP_DIR=/usr/bin` を置く。

## シェル

コンテナの zsh は、Arch の Oh My Zsh と Powerlevel10k から、wsl2-ssh-agent、khal、docker、docker-compose を外したもの。最初から入っているのは yazi、proto、paru、screenfetch。`yay` は `paru` の別名。`vi` と `vim` は `nvim`。

プロンプトのアイコンは WezTerm のフォント（Moralerspace Neon HWJPDOC）に依存する。`wslc-dev/home/.p10k.zsh` は `archlinux/.p10k.zsh` のコピーであり、同時に更新されるリンクではない。個人差分は `~/.zshrc.local` に書く。

## Git

`/workspace` 配下のリポジトリはコンテナの git で操作する。Windows の Git とコンテナの Git が同じ `.git/index` を書くと、index の作り直しが走る。

設定の編集先は `wslc-dev/home/.gitconfig`。Windows の `~/.gitconfig` は書き換えない。

- `safe.directory` は `/workspace` と `/workspace/*`。`**` はマッチしない。
- `core.filemode=false`、`core.checkStat=minimal`、`core.trustctime=false`。
- ユーザー名、メール、署名鍵はこのファイルが正である。
- リポジトリローカルの `core.filemode=true` は、グローバルの false より優先される。

VirtioFS 上の既存の Windows ファイルは mode 777、uid 0 に見え、chmod は Operation not permitted になる。コンテナ内で新規作成したファイルは通常の権限を持てる。

## SSH

entrypoint が `/mnt/win-ssh` の通常ファイルを、ドットファイルと `*.swp` を除いて `~/.ssh` へコピーする。ディレクトリは 700。秘密鍵は 600。`*.pub`、`config`、`known_hosts`、`known_hosts.old` は 644。マウント元の権限は変えない。秘密鍵の中身は、ログ、チャット、ドキュメントに出さない。

1Password の `op-ssh-sign.exe` によるコミット署名は、コンテナには繋いでいない。

## Neovim

設定は3つに分ける。

- 開発リポジトリはコンテナの `wslc-dev/home/.config/nvim`。LazyVim 一式はまだ移していない。クリップボードは `vim.ui.clipboard.osc52` があるときだけ OSC 52 を使う。Markdown は `render-markdown.nvim` と `markdown.nvim`。言語サーバーと Mason は入れない。プラグインデータはホームボリュームに置く。
- Windows のファイルは `windows/`。Neovim は `windows/nvim`。`windows/install-powershell.ps1` が winget の `Neovim.Neovim` を入れ、`%LOCALAPPDATA%\nvim` へリンクする。クリップボードは未設定のままにする。Markdown プラグインはコンテナと同じ構成で、設定ファイルは共有しない。言語サーバーと Mason は入れない。プラグインデータは `%LOCALAPPDATA%\nvim-data` に置く。
- Arch 用の `archlinux/.config/nvim` は消さない。Windows やコンテナの設定へ流用しない。

## 保留

次は、明示されるまで着手しない。

- Arch の nvim アンインストール
- Arch 用 dotfiles とコンテナ用コピーの統合
- LazyVim 設定の移植
- コンテナでの 1Password コミット署名
