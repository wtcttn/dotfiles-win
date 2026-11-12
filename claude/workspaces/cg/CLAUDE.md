# CG（Blender と After Effects）

このファイルと `.mcp.json` の正本は dotfiles の `claude/workspaces/cg/` である。ここで直さず dotfiles を直し、`windows/install-powershell.ps1 claude` で入れ直す。

このフォルダで起動した Claude Code だけが、Blender と After Effects の MCP を使える（このフォルダの `.mcp.json`、project スコープ）。作業するファイルはこのフォルダに置かなくてよい。

## 使える MCP

| 名前 | 中身 |
| --- | --- |
| `blender` | 公式 Blender Lab MCP（v1.0.3）。ポート 9877。Python API とマニュアルの検索、スクリーンショット、`*_for_cli` で裏の Blender も使える |
| `blender-community` | mcp-for-blender（ahujasid）。ポート 9876。Poly Haven の素材検索と Tripo の 3D 生成。送信データはオフ |
| `after-effects` | TheLlamainator/after-effects-mcp（`C:\Users\kento\after-effects-mcp`） |

## 承認が要ること

次はオーナーの承認が依頼文にあるときだけ行う。

- Tripo の生成（`generate_3d`）。Blender MCP 経由の Tripo は Studio の契約とは別の API クレジットを使う
- 保存済みの .blend や .aep の上書き、レンダリングや書き出し
- 開いているシーンやコンポを大きく変える操作。先に保存を勧める

## Blender

- 本体は `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`。ほかの版は無い。
- 両方のアドオンは Blender の起動時にサーバーを自動で立てる。つながらないときは `Get-NetTCPConnection -LocalPort 9876,9877` で待ち受けを見る。
- 公式版は Blender の「オンラインアクセスを許可」がオフだと黙って起動しない。
- Blender は終了時にプリファレンスを自動保存する。設定は Blender を閉じて `blender -b --python` で変えるか、起動中の Blender に MCP で変えてから `bpy.ops.wm.save_userpref()` する。
- mcp-for-blender は Poly Haven や Tripo のオンオフをシーンごとに持つ。`%APPDATA%\Blender Foundation\Blender\5.2\scripts\startup\blendermcp_defaults.py` が、開いたファイルで両方をオンにする。
- mcp-for-blender の `install-addon` は 5.2 ではなく古い版のフォルダに書くので、更新したら `blender_mcp.py` を `5.2\scripts\addons` に手で写す。

## After Effects

- AE 2026 だけ設定済み。ウィンドウメニューから `mcp-bridge-auto.jsx` のパネルを開いておく。
- 環境設定の「スクリプトとエクスプレッション」で「スクリプトによるファイルへの書き込みとネットワークへのアクセスを許可」をオンにする。
- サーバーと AE は `Documents\ae-mcp-bridge` のファイルでやりとりする。

## 制作の決まり

制作フォルダ（`C:\Users\kento\workspace\productions\<作業名>\`）の仕事では、制作の決まりの正本である production-kit（`C:\Users\kento\workspace\wtcttn\production-kit`）の `RULES.md` と、制作フォルダの `README.md` に従う。共通の道具は production-kit の `tools/` を使い、制作フォルダに写さない。
