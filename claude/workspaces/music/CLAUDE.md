# 音楽（Studio One と音素材）

このファイルと `.mcp.json` の正本は dotfiles の `claude/workspaces/music/` である。ここで直さず dotfiles を直し、`windows/install-powershell.ps1 claude` で入れ直す。

このフォルダで起動した Claude Code だけが、音楽系の MCP を使える（このフォルダの `.mcp.json`、project スコープ）。曲のファイルはこのフォルダに置かなくてよい。

## 使える MCP

| 名前 | 中身 |
| --- | --- |
| `studio-one` | NeanderthalMan/studio-one-mcp v0.3.0。Studio One 6.6.4 |
| `splice` | Splice の公式 MCP（素材の検索、スタック） |
| `musio-studio` | ローカルの HTTP サーバー（127.0.0.1:47823）。起動していないとつながらない。認証ヘッダはユーザー環境変数 `MUSIO_STUDIO_AUTH` から読む（値は git に入れない） |
| `suno` | Suno の公式 MCP（`https://api.suno.com/mcp`、2026-11-08 から）。プレミアプラン。初回は `/mcp` からオーナーがログインする |
| `myinstants` | myinstants-mcp 1.8.2。Myinstants の効果音の検索と取得（2026-11-09 から） |

## 承認が要ること

次はオーナーの承認が依頼文にあるときだけ行う。

- ソングの保存（`live_save`）、書き出し（`live_bounce`）、録音
- Splice の素材のダウンロードやクレジットを使う操作、スタックの共有
- Suno の生成とダウンロード（どちらもクレジットを使う）

## 素材の出どころ

- Myinstants は利用者が上げた切り抜きで、規約も権利者も確かめられない。ショート動画のネタ系の効果音に使うのは、オーナーが認めた制作だけにする（2026-11-09 の出口クイズで認めた）。使ったものは、制作フォルダの記録に名前と出どころを残す。
- 効果音ラボなど規約のある素材は、規約（クレジット、再配布の禁止）を制作フォルダの記録に書き写す。

## 声

AI ボイスは E ドライブに入れてある（C ドライブには入れない）。`E:\voice\AivisSpeech`（ポート 10101）と `E:\voice\VOICEVOX`（ポート 50021）。公開するときは、使った声のクレジットを概要欄に入れる（春歌ナナ、AI声優-銀芽などは必須）。

## Studio One の癖

- loopMIDI を Studio One より先に起動する。後だと ping が返らない。
- プロファイルは `C:\Users\kento\AppData\Roaming\PreSonus\Studio One 6` を明示する（自動判定はクラッシュダンプを拾う）。
- `live_edit_notes` の前に、止めてから `live_select_track` で対象のトラックを選び直す。編集は今選ばれているトラックにも漏れることがある。
- `add` は、最初に見つかったノートのパート（スクラッチのコピーのこともある）に入る。結合したパートでは、最初のイベントの位置だけずれる。追加のあとは、関係する全パートのノート数を見比べる。
- 再生中や、オートメーション・ミキサーを触った直後は「MCP Edit is not available」になる。止めてトラックを選び直す。
- 楽器トラックのチャンネルへの `live_add_plugin` は「ambiguous」で失敗する。プラグインはオーナーに手で挿してもらう。
- サードパーティのプラグイン（Kilohearts、ZEN）はパラメーター名が読めない。つまみの値を伝えて手で合わせてもらう。
