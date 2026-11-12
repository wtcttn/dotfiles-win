---
name: hub-keeper
description: >-
  Keeps the Claude Code session "hub" on SUGIMOTO-PC available for Grok Bot's
  参謀. Checks whether hub is up (hub-bridge ping, then the WezTerm mux pane
  list), starts it with Start-Hub when it is missing, and, with the owner's
  approval, restarts it (ccx hub -Force, then Start-Hub) when it is frozen.
  Runs PC commands through the Grok Bot desktop app. Use when hub-bridge
  cannot be reached, or when the owner asks to start or restart hub. Never
  types into panes (no send-text) and never starts other panes; hub does that.
---

# hub を用意しておく（hub-keeper）

Grok Bot の「参謀」が、SUGIMOTO-PC の Claude Code `hub` を使える状態に保つ手順である。依頼と返事は、スキル `hub-bridge`（MCP サーバー `hub-bridge`）で行う。このスキルは、hub がいないとき、固まっているときだけ使う。2026-11-12 までの `wezterm-claude-mcp`（send-text で画面に打ち込む）の代わりである。

取り決めの正本は dotfiles の `grokbot/claude-code.md`。PC 側のコマンド（`Start-Hub`、`ccx`、`ccs`）は、dotfiles の PowerShell プロファイル `windows/Microsoft.PowerShell_profile.ps1` にある。

## 前提

- PC のコマンドは、Grok Bot のデスクトップアプリで SUGIMOTO-PC を指定して実行する。オーナーのユーザーで、PowerShell のプロファイルを読み込んで動く（端末でないときは画面まわりの設定を飛ばし、関数だけを読む）。
- 実行のたびに Grok Bot の自動の安全確認が入る。止められたときだけ、オーナーに承認のカードが出る。`Start-Hub` を常に許すには、オーナーが Auto-review の許可ルールを足す（参謀からカードで提案してよい）。
- hub は WezTerm の mux（ウィンドウを閉じても残る）に常駐する。mux のサーバーが動いていなくても、`wezterm cli` が自動で起動する。WezTerm の画面は開かない（開く操作はウィンドウを増やすので使わない）。

## 1. hub がいるか見る

1. `hub-bridge` の `ping` を呼ぶ。返事があれば hub はいる。ここで終わる。
2. つながらないときは、PC で mux のペインの一覧を見る。

   ```powershell
   wezterm cli --prefer-mux list --format json
   ```

   `tab_title` が `hub` のペインがあるかを見る（タイトルの末尾が `hub` のものでもよい）。

## 2. いなければ立ち上げる

一覧に hub が無ければ、PC で次を実行する。

```powershell
pwsh -NoLogo -Command "Start-Hub"
```

- `Start-Hub` は、mux に hub が無ければ、mux の既存のウィンドウにタブを足して `cc hub` を起動する。あれば何もしない。何度呼んでもウィンドウもタブも増えない。
- hub は起動のたびに、開発用チャネルの確認（`WARNING: Loading development channels` と「1. I am using this for local development / 2. Exit」）で止まる。研究プレビューの間は、これを飛ばす公式の方法が無い。参謀は答えない（`send-text` で打ち込まない）。30秒ほどたったら hub の画面を `get-text`（3 のコマンド）で読み、この確認が出ていれば「hub のペインで 1 を選んでほしい」とオーナーに知らせる（PC の WezTerm で選ぶ。Remote Control はこの確認のあとにつながるとみられ、スマートフォンからは選べない見込み）。
- オーナーが選んでから hub-bridge が待ち受けるまで、30秒ほどかかる。30秒おきに `ping` を見て、選んでから2分たっても返事が無ければ 3 に進む。
- Bitwarden の解錠の控え（12時間）が切れていると、hub のペインでマスターパスワードを聞かれて止まる。そのときは「hub のペインで Bitwarden のマスターパスワードの入力が要る」とオーナーに知らせる。

## 3. 固まっていないか見る

hub のペインはあるのに `ping` が返らないときは、hub の画面の最後を読む（hub のペインだけ。ほかのペインの画面は読まない）。

```powershell
wezterm cli --prefer-mux get-text --pane-id <hub の pane_id> --start-line -40
```

- マスターパスワードを聞いている → オーナーに入力を頼む。
- 承認の確認（ツールの許可など）で止まっている → オーナーに知らせる。参謀は答えない。
- 動いている途中（考え中の表示）なら、少し待って `ping` をやり直す。
- エラーで止まっている、または何分も変わらない → 4 へ。

## 4. 起動し直す（オーナーの承認が要る）

オーナーに、何が起きているかを一文で伝え、起動し直してよいかを聞く。認められたら、PC で次を実行する。

```powershell
pwsh -NoLogo -Command "ccx hub -Force; Start-Hub"
```

- 起動し直した hub は新しい会話になり、`workspace\hub` のいちばん新しい引き継ぎのファイルを読んでから始める。参謀は、途中だった依頼の id を `send_to_hub` で送り直す（同じ id で送れば二度は届かない）。
- 起動し直しても `ping` が返らなければ、オーナーに知らせて止まる。

## しないこと

- ペインに文字を打ち込まない（`send-text` は使わない）。依頼は `hub-bridge` で送る。
- hub 以外のペインの画面を読まない。hub 以外のペインを立ち上げたり閉じたりしない（足りないペインは hub に頼む。hub が `ccs` で立ち上げる）。
- hub を閉じる（`ccx hub -Force`）のは、オーナーが認めたときだけ。
- `wezterm cli` の `spawn`、`kill-pane`、`split-pane` を直接使わない（`Start-Hub` と `ccx` を通す）。
- PC の Tailscale のアドレス、鍵、Bitwarden の値を、ノート、会議室、報告に書かない。

## Grok Bot

ボックスのボルトは `/home/box/sync/obsidian-vault`（`~/notes` はここへのリンク）。Grok Bot が書くノートの `source` は `grok-bot`。
