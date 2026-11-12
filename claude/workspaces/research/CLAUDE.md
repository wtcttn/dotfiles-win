# 調査（Grok Bot のマーケターから直接呼ばれる）

このファイルの正本は dotfiles の `claude/workspaces/research/` である。ここで直さず dotfiles を直し、`windows/install-powershell.ps1 claude` で入れ直す。

このフォルダ（`C:\Users\kento\workspace\research`）の下の作業フォルダで動く Claude Code は、Grok Bot の「マーケター」（調査と分析の担当）から `claude -p` で直接呼ばれ、1回に1つの調査をする。hub と hub-bridge は通らない。取り決めの正本は dotfiles の `grokbot/claude-code.md` の「調査を直接呼ぶ（マーケター）」で、起動は同じフォルダの `run-research.ps1` が行う。アプリの MCP は持たない。

## 作業フォルダ

調査のたびに `C:\Users\kento\workspace\research\<YYYYMMDD>_<題名>\` を作る（作るのはマーケター）。題名は英小文字とアンダースコア。

| 置くもの | 書く人 | 中身 |
| --- | --- | --- |
| `request_NN.md` | マーケター | 目的、問い（1〜3）、範囲、締め切り、出力の形、禁止事項。雛形は `templates/request.md` |
| `report_NN.md` | Claude Code | 要点3行、確かなことと推測を分けた本文、出典の URL と確かめた日時。雛形は `templates/report.md` |
| `sources\` | Claude Code | 集めた資料（ページの写し、表、スクリーンショット）。ファイル名は `NN_<中身>.<拡張子>` |
| `prompt_NN.txt`、`run_NN.log`、`run_NN.err`、`report_NN.done` | `run-research.ps1` | 渡した指示、最後の返事、エラー、終わりの印 |

- 番号 `NN` は `01` から。追加の問いややり直しは、番号を上げた `request_NN.md` で受ける。前の番号のファイルは書き換えない。
- `report_NN.md` は締め切りの前に必ず書く。調べきれなかったときも、わかったところまでと、残った問いを書く。

## すること

1. `request_NN.md` を読む。問い、範囲、締め切り、禁止事項から外れない。
2. 調べる。Web は WebSearch と WebFetch、ログインが要るもの（X、YouTube Studio など）は Chrome。資料は `sources\` に写す。
3. `report_NN.md` を書く。
   - 先頭に要点を3行。
   - 本文は「確かなこと」（出典で確かめた事実。数字は出典ごと）と「推測」（自分の読み。根拠を添える）を分ける。
   - 出典は、URL と確かめた日時（`2026-11-12 21:30` の形）を並べる。`sources\` に写したものはそのパスも書く。
4. 最後の返事（`run_NN.log` に残る）は、`report_NN.md` のパスと要点3行だけにする。

## Chrome

- ログイン中の Chrome を使う（`--chrome`）。読むだけにする。投稿、返信、いいね、リポスト、フォロー、ブックマーク、購入・課金、設定の変更、フォームの送信はしない。ログインやパスワードの入力もしない。ログインが切れていたら、そこで止めて report に書く。
- ことねの巡回（2時間ごと）が同じ Chrome でおすすめを読む。`run-research.ps1` が、巡回の時間帯を避け、使用中の印（`chrome.lock`）を置いてから起動する。印を自分で消したり書き換えたりしない。
- タブは新しく開き、終わったら自分で開いたタブだけ閉じる。オーナーのタブは触らない。

## しないこと

- ボルト（`C:\Users\kento\notes`）に書かない。残すものはマーケターがノート管理に頼む。
- 作業フォルダの外に書かない（`run-research.ps1` も、書き込みを作業フォルダの中に限って起動する）。
- 課金のある API や生成を使わない。メール、DM、フォームの送信をしない。
- 秘密の値（パスワード、トークン、鍵、IP）を report や sources に書かない。画面に出たら伏せる。
