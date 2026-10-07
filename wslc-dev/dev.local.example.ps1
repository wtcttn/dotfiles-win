# dev.local.ps1 の書式例。dev.local.ps1 にコピーして使う（dev.local.ps1 は git で管理しない）。
# dev.ps1 が読み込む。変更したら .\wslc-dev\dev.ps1 recreate する。

# 追加のボリューム（ボリューム名 => コンテナ内のパス）。無ければ作成する（動的 VHD、10GiB、uid/gid 1000）。
# 例: リポジトリの node_modules を VirtioFS ではなくボリュームに置く。
# $ExtraVolumes["wslc-dev-<org>-<repo>-node-modules"] = "/workspace/<org>/<repo>/node_modules"
