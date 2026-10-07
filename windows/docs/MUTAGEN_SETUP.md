# Mutagen Setup

[Mutagen](https://mutagen.io/) は、Windows のディレクトリと WSLc のボリューム（ext4）をリアルタイムに双方向同期するために使う。
Windows 側のファイルを VirtioFS でコンテナに見せると小さいファイルの I/O が極端に遅いため、コンテナには同期先のボリュームを見せる。

## インストール

winget と Chocolatey には無い（2026-10 時点）。Scoop の main バケットから入れる。

```powershell
scoop install mutagen
mutagen version          # 0.18.1 で確認
```

- 実体: `~\scoop\apps\mutagen\current`、コマンド: `~\scoop\shims\mutagen.exe`
- 更新: `scoop update mutagen`（更新後は `mutagen daemon stop; mutagen daemon start`）
- アンインストール: `mutagen sync terminate --all; mutagen daemon stop; scoop uninstall mutagen`

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
