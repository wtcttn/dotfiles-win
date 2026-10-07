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
- `wslc-dev` 以外の WSLc のコンテナ、ネットワーク、ボリューム（プロジェクトのアプリ用スタック）。管理しているのは各プロジェクト側である

## レイアウト

| 名前 | 実体 | コンテナ内 |
| --- | --- | --- |
| イメージ `wslc-dev:local` | `wslc-dev/Dockerfile` | |
| コンテナ `wslc-dev` | `wslc-dev/dev.ps1` が作成 | |
| ボリューム `wslc-dev-home` | 動的 VHD、20GiB、uid/gid 1000 | `/home/kento` |
| ワークスペース | `C:\Users\kento\workspace` | `/workspace` |
| 設定 | `wslc-dev/home` | `/opt/wslc-dev/home` |
| Windows SSH | `C:\Users\kento\.ssh`（読み取り専用） | `/mnt/win-ssh` |
| 追加のボリューム | `dev.local.ps1` の `$ExtraVolumes`。動的 VHD、10GiB、uid/gid 1000 | `dev.local.ps1` で指定（例: リポジトリの `node_modules`） |

リポジトリの `node_modules` は Windows 側（VirtioFS）に置くと `pnpm install` や `tsc` が極端に遅いので、コンテナ専用のボリュームを重ねる。プロジェクトのアプリ用コンテナの node_modules とは別のボリュームにする。

マシンやプロジェクトに固有の設定（追加のボリュームなど）は `wslc-dev/dev.local.ps1` に書く。このファイルは `.gitignore` で除外していて、`dev.ps1` が読み込む。書式は `wslc-dev/dev.local.example.ps1`。プロジェクトの名前やパスは、`dev.ps1` を含め git で管理するファイルに書かない。変更したら `recreate` する。

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
- `packages-save` は、コンテナに入れたパッケージの一覧を `wslc-dev/home/packages/` に書き出す。
- `packages-restore` は、その一覧からパッケージを入れ直す。`recreate` のあとに使う。

マウントはコンテナ作成時に固定される。`up` と `start` では新しい `-v` は付かない。Dockerfile と entrypoint を変えたあとは `build` してから `recreate` する。

`wslc list` と `wslc volume list` の `--format json` は NDJSON である。`inspect --format` は JSON であり、Go テンプレートではない。

`dev.ps1` では、関数引数に `-d` を渡さない。PowerShell が `-Debug` に取る。継続行の先頭を `--opt` にしない。`wslc` への引数は文字列配列で `Invoke-Wslc` に渡す。

WezTerm の既定は `wslc-dev/wezterm.cmd` である。`wslc start wslc-dev` のあと `wslc exec -it -u kento -w /workspace wslc-dev zsh` を実行する。反映には新しいウィンドウが要る。Arch はランチャに残す。

## パッケージ

イメージに残る定義は Dockerfile である。公式パッケージの `pacman -S`、`/usr/bin` の proto、AUR の `paru` を `makepkg -si` で入れる箇所が、Brewfile に相当する。

Dockerfile はベース（シェル、エディタ、proto、paru）だけにする。開発で使うパッケージは、走っているコンテナに `pacman -S` / `paru -S` で入れ、`dev.ps1 packages-save` で一覧を `wslc-dev/home/packages/` に書き出して git で管理する。

| ファイル | 中身 | 書き出し元 |
| --- | --- | --- |
| `packages/pacman.txt` | 明示インストールした公式パッケージ | `pacman -Qqen` |
| `packages/aur.txt` | 明示インストールした AUR パッケージ | `pacman -Qqem` |
| `packages/proto.txt` | proto のツールとバージョン（1 行に `tool version`） | `~/.proto/tools/*/*` |
| `packages/prototools.toml` | proto のグローバル設定 | `~/.proto/.prototools` |

パッケージを足したら `packages-save` して、差分をコミットする。`recreate` すると書き込み層のパッケージは消えるので、`packages-restore` で入れ直す。proto のツール本体と gem はホームボリュームにあるので `recreate` では消えない。

同じコンテナを使い続けるあいだの更新は、コンテナの中で `paru -Syu` する。`down` して `up` しても残る。

`pacman -Syu` だけにはしない。libalpm の soname が上がると paru が動かなくなる。`paru-bin` は入れない。イメージの pacman は `libalpm.so.16` で、paru は AUR の `paru` をソースからビルドする。

Oh My Zsh、Powerlevel10k、zsh-autosuggestions、zsh-syntax-highlighting は pacman パッケージではない。`/usr/share/oh-my-zsh` への git clone である。`zstyle ':omz:update' mode disabled`。これらの更新をイメージに残すときも Dockerfile を rebuild する。

走っているコンテナの明示インストールを控えるときは、次で公式と AUR を分ける。

```bash
pacman -Qqen > pkglist.txt
pacman -Qqem > aurlist.txt
```

`packages-save` / `packages-restore` はこの手順をまとめたもの。この一覧をイメージの定義にはしない。

proto のバイナリは `/usr/bin/proto` と `/usr/bin/proto-shim`。ツール本体はホームボリュームの `~/.proto` に入る。zsh は `PROTO_HOME=$HOME/.proto` と `PROTO_LOOKUP_DIR=/usr/bin` を `.zshenv` と `.zshrc` の両方に置く（`.zshenv` は git フックなど非対話の `zsh -c` 用、`.zshrc` はログインシェルで `/etc/profile` が PATH を上書きした後の再設定）。

## 言語ランタイム

ruby / node / pnpm は proto で入れる。バージョンはリポジトリのファイルから自動で選ばれる（`.ruby-version`、`.node-version`、`package.json` の `engines` と `packageManager`）。リポジトリに `.prototools` は置かない。

- グローバルの既定は node だけ固定する（`proto pin --to global node <version>`）。pnpm のインストールに node の指定が要るため。
- 新しいバージョンが要るときは、そのリポジトリで `proto install <tool> <version>` してから `packages-save`。
- gem はホームボリュームの proto の ruby に入る（`bundle install`）。ネイティブ拡張用に `cmake`、`postgresql-libs`、`libyaml` を pacman で入れている。
- Playwright（vitest のブラウザテストなど）を使うリポジトリがある。Playwright は Arch 用の依存の自動インストール（`--with-deps`）に対応していないので、必要な共有ライブラリは pacman の `chromium` を入れて揃え、ブラウザ本体はそのリポジトリで `pnpm exec playwright install chromium`（`~/.cache/ms-playwright`、ホームボリューム）で入れる。

リポジトリの git フック（bundle install / pnpm install、husky の lint / tsc / test など）は、このコンテナの git で動く。そのため、フックが使うランタイムと依存をこのコンテナに入れておく。

## シェル

コンテナの zsh は、Arch の Oh My Zsh と Powerlevel10k から、wsl2-ssh-agent、khal、docker、docker-compose を外したもの。イメージに最初から入っているのは yazi、proto、paru、screenfetch。それ以外は `wslc-dev/home/packages/` を参照。`yay` は `paru` の別名。`vi` と `vim` は `nvim`。

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

- 開発リポジトリはコンテナの `wslc-dev/home/.config/nvim`。LazyVim。エクスプローラーは Snacks（`<leader>e`）。Git の差分は gitsigns、Snacks の `<leader>gd`、Diffview の `<leader>gv`。クリップボードは `vim.ui.clipboard.osc52` があるときだけ OSC 52 を使う。プラグインデータはホームボリュームに置く。
- Windows のファイルは `windows/`。Neovim は `windows/nvim`。`windows/install-powershell.ps1` が winget の `Neovim.Neovim` を入れ、`%LOCALAPPDATA%\nvim` へリンクする。LazyVim の構成はコンテナと同じだが、設定ファイルは共有しない。クリップボードは未設定のままにする。プラグインデータは `%LOCALAPPDATA%\nvim-data` に置く。
- Arch 用の `archlinux/.config/nvim` は消さない。Windows やコンテナの設定へ流用しない。

## 保留

次は、明示されるまで着手しない。

- Arch の nvim アンインストール
- Arch 用 dotfiles とコンテナ用コピーの統合
- コンテナでの 1Password コミット署名
