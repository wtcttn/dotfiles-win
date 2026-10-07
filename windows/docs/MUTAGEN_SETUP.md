# Mutagen Setup

[Mutagen](https://mutagen.io/) は、Windows のディレクトリと WSLc のボリューム（ext4）をリアルタイムに双方向同期するために使う。
Windows 側のファイルを VirtioFS でコンテナに見せると小さいファイルの I/O が極端に遅いため、コンテナには同期先のボリュームを見せる。

## インストール

`install-powershell.ps1` に組み込んである（`install` 全体でも入る）。下の「使う ssh を固定する」「デーモン」まで一度に行う。

```powershell
.\windows\install-powershell.ps1 mutagen
```

手動で行う場合: winget と Chocolatey には無い（2026-10 時点）ので、Scoop の main バケットから入れる。

```powershell
scoop install mutagen
mutagen version          # 0.18.1 で確認
```

- 実体: `~\scoop\apps\mutagen\current`、コマンド: `~\scoop\shims\mutagen.exe`
- 更新: `scoop update mutagen`（更新後は `mutagen daemon stop; mutagen daemon start`）
- アンインストール: `mutagen sync terminate --all; mutagen daemon stop; scoop uninstall mutagen`

## 使う ssh を固定する

Mutagen は SSH の接続先に `ssh` コマンドを使う。PATH の状況によっては Git for Windows の ssh（MSYS）が使われ、
`~/.ssh/config` の `Include` に書いた `C:/...` 形式のパスを読めずに接続に失敗する。Windows の OpenSSH に固定する。

```powershell
[Environment]::SetEnvironmentVariable('MUTAGEN_SSH_PATH', 'C:\Program Files\OpenSSH', 'User')
mutagen daemon stop; mutagen daemon start   # 新しい環境変数で起動し直す（新しいターミナルから）
```

`~/.ssh/config` に書くパスは、どちらの ssh でも同じ場所になるよう `~/...` の形にしておくと安全。

## デーモン

同期はバックグラウンドのデーモンが行う。ログオン時に自動で起動させる。

```powershell
mutagen daemon register  # ログオン時の自動起動を登録（解除は mutagen daemon unregister）
mutagen daemon start
```

## 使い方の要点

- 同期セッションの作成・削除は、使う側（プロジェクトの起動スクリプト）が行う。ここでは Mutagen 本体だけを管理する。
- 状態確認: `mutagen sync list`、詳細な監視: `mutagen sync monitor <name>`
- 競合した場合: `mutagen sync list` に `Conflicts` が表示される。どちらかの側でファイルを直してから `mutagen sync flush <name>`。
- WSLc のボリュームへは SSH で接続する（WSLc には Docker API が無いので Mutagen の `docker://` は使えない）。
