---
name: research-request
description: >-
  Lets Grok Bot's マーケター (research and analysis) run one research job on
  SUGIMOTO-PC by calling Claude Code directly with claude -p, without hub or
  hub-bridge. Creates the work folder C:\Users\kento\workspace\research\<YYYYMMDD>_<title>\,
  writes request_NN.md from the template, starts run-research.ps1 in the
  background through the Grok Bot desktop app, waits for report_NN.done, and
  passes on the path of report_NN.md. Chrome is read-only and shared with
  ことね's patrol, so the script avoids patrol hours and uses chrome.lock. Use
  when the マーケター needs web or logged-in research. Never writes results to
  the vault inbox; the path goes to ノート管理 only when something should be kept.
---

# 調査を直接呼ぶ（research-request）

Grok Bot の「マーケター」（調査と分析の担当）が、SUGIMOTO-PC の Claude Code に調査を1つ頼む手順である。hub と hub-bridge は通さない。取り決めの正本は dotfiles の `grokbot/claude-code.md` の「調査を直接呼ぶ（マーケター）」で、呼ばれた Claude Code の決まりは `claude/workspaces/research/CLAUDE.md`。食い違ったら正本に従う。

## 前提

- PC のコマンドとファイルの読み書きは、Grok Bot のデスクトップアプリで SUGIMOTO-PC を指定して行う。PC がオフなら調査はできない。ほかの手で代わりにしない。
- PC のコマンドには自動の安全確認（Auto-review）が入る。止められたら、オーナーの承認カードを待つ。許可のルールを自分で変えない。
- 起動スクリプトは `C:\Users\kento\dotfiles\claude\workspaces\research\run-research.ps1`、雛形は同じフォルダの `templates\request.md`・`templates\report.md`。

## 1. 依頼を書く

1. 作業フォルダ `C:\Users\kento\workspace\research\<YYYYMMDD>_<題名>\` を作る。題名は英小文字とアンダースコア（例: `20261112_shorts_trend`）。調査のたびに新しく作る。続きの問いは、同じフォルダで番号を上げる。
2. 雛形 `templates\request.md` を写して `request_NN.md`（`01` から）を書く。目的、問い（1〜3）、範囲、締め切り、出力の形、禁止事項を埋める。Chrome が要るかも書く。
3. 締め切りは、起動の `-MaxMinutes` の打ち切りより前にする。

## 2. 起動する

Chrome を使うなら、先に始められるかを見る（ことねの巡回と取り合わないため）。

```powershell
& "$env:USERPROFILE\dotfiles\claude\workspaces\research\run-research.ps1" -CheckOnly -MaxMinutes 60
```

`ok:` なら起動する。`wait:` は書いてある時刻まで待つ。`busy:` はほかの調査が終わるのを待つ。

```powershell
& "$env:USERPROFILE\dotfiles\claude\workspaces\research\run-research.ps1" -Dir C:\Users\kento\workspace\research\20261112_shorts_trend -N 01 -MaxMinutes 60 -Background
```

- Chrome が要らないときは `-NoChrome`（巡回の時間帯でも始められる）。
- 昼に Chrome を使う調査は、偶数時の30分から70分以内に収める（例: 10:30〜11:40）。長いものは 0:30〜7:20 に回すか、問いを分ける。
- 終了コード 3（巡回の時間帯）と 4（Chrome を使用中）は、待ってから同じコマンドで呼び直す。

## 3. 待つ

1. 1〜2分おきに `report_NN.done` があるかを見る（`Test-Path`）。`-MaxMinutes` に10分を足しても無ければ、オーナーに知らせる。
2. 1行目を見る。`done 0` は成功。`done <0 以外>` は失敗で、`run_NN.err` を読む。`timeout` は打ち切りで、`report_NN.md` があれば途中までの結果。
3. `report_NN.md` を読み、問いに答えているか、確かなことと推測が分かれているか、出典に URL と日時があるかを見る。足りなければ、番号を上げた `request_NN.md` で頼み直す。

## 4. 渡す

- 結果は作業フォルダに置いたままにする。ボルトの inbox に入れない。
- 頼んだ相手には、`report_NN.md` のパスと要点3行を渡す。
- ノートに残すものがあれば、ノート管理に要点とパスを頼む。Claude Code にはボルトに書かせない。

## しないこと

- Chrome で書き込むこと（投稿、返信、いいね、リポスト、フォロー、ブックマーク、購入・課金、設定の変更、フォームの送信）を頼まない。
- `chrome.lock` を消したり書き換えたりしない（起動スクリプトが扱う）。ことねの巡回の時間帯に、Chrome を使う調査を無理に始めない。
- hub や hub-bridge 経由で調査を頼まない（それは参謀の窓口）。
- 依頼文、報告、メッセージに、秘密の値（パスワード、トークン、鍵、IP）を書かない。

## Grok Bot

ボックスのボルトは `/home/box/sync/obsidian-vault`（`~/notes` はここへのリンク）。Grok Bot が書くノートの `source` は `grok-bot`。
