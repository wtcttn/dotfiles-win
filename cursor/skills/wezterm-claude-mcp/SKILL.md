---
name: wezterm-claude-mcp
description: >-
  Connect from Grok Bot to Claude Code running in existing WezTerm mux
  sessions on SUGIMOTO-PC or other machines, to delegate MCP-driven work
  (blender-mcp, after-effects MCP) to Claude running closer to the
  application. Use when the user asks to send a task to Claude on a
  specific machine, control Blender/After Effects through Claude, or
  orchestrate multi-machine creative workflows.
---

# WezTerm mux 経由の Claude Code への連携

Grok Bot から、SUGIMOTO-PC など別のマシン上の WezTerm mux セッションで既に起動している Claude Code に指示を送るスキルである。Blender MCP や After Effects MCP など、アプリに近い Claude が持つツールを使った制作に連携する。

## 原則

- **機械固有情報をハードコードしない**。pane id や端末名は実行時に `wezterm cli --prefer-mux list` で取得し、ユーザーが指示した作業に合う pane を選ぶ。
- **全 Bot で汎用的に使える**。Windows PowerShell、Linux bash、macOS zsh でのコマンド例を記載し、環境ごとに分岐する。
- **既存の作業を止めない**。送信前に必ず現在の画面を読み、入力欄が空か、Claude が入力待ち状態であることを確認する。意図した pane であることも確認する。
- **明確な完了確認をする**。応答は `get-text` で読み、明確な完了確認のない状態を完了扱いしない。長時間走るジョブは無計画にポーリングせず、必要な場面で状態を見る。
- **破壊的操作をしない**。`spawn` は使わない（現在の nightly では外部 spawn が mux server を固める問題があり、大量タブ発生の原因）。`kill`、`split` 等の破壊的・構造変更コマンドも明示依頼なしに行わない。
- **権限と承認を明示する**。課金・公開・SNS投稿・送信・保存済み制作物の変更などはユーザー本人の承認を必要とする。WezTerm 経由で Claude に送る場合、MCP を使ったアプリ側の操作権限と、ユーザーのリクエストの範囲を明示する。

## WezTerm CLI の基本

WezTerm の unix ドメイン `mux` に置かれた常駐ペインと通信する。GUI を閉じても残るセッションである。

### pane 一覧の取得

Windows PowerShell:
```powershell
wezterm cli --prefer-mux list
```

Linux bash / macOS zsh:
```bash
wezterm cli --prefer-mux list
```

出力例（TSV 形式）:
```
0  0  0  /workspace  Running  zsh
1  1  0  /workspace  Running  zsh
2  2  0  /workspace  Running  zsh
```

各行は `window_id  tab_id  pane_id  cwd  state  title` である。**pane_id（3列目）** を特定する。

### 画面の現在の内容を読む

Windows PowerShell:
```powershell
wezterm cli --prefer-mux get-text --pane-id 1 --start-line -300
```

Linux bash / macOS zsh:
```bash
wezterm cli --prefer-mux get-text --pane-id 1 --start-line -300
```

`--start-line -300` は最近の300行を取得する。Claude Code のプロンプトが表示されているか、既に作業中かを確認する。

### テキストを送信してEnterを押す

**重要**: テキスト本文と Enter（改行）は別々に送る。`\`r` を文字列として引数に渡さない（PowerShell のエスケープシーケンスとして解釈されるため）。

Windows PowerShell:
```powershell
$text = "Blenderで新しいキューブを追加してください"
$text | wezterm cli --prefer-mux send-text --pane-id 1 --no-paste
[char]13 | wezterm cli --prefer-mux send-text --pane-id 1 --no-paste
```

Linux bash / macOS zsh:
```bash
text="Blenderで新しいキューブを追加してください"
echo -n "$text" | wezterm cli --prefer-mux send-text --pane-id 1 --no-paste
printf '\r' | wezterm cli --prefer-mux send-text --pane-id 1 --no-paste
```

`--no-paste` は paste モードを使わず、直接入力として送る。

## 実行手順

1. **pane の特定**
   - `wezterm cli --prefer-mux list` で pane 一覧を取得。
   - タブ名やタイトル、cwd から、Blender 用なら `blender` タブ、After Effects 用なら `aftereffects` タブを探す。
   - pane_id を記録する。

2. **現在の状態を確認**
   - `wezterm cli --prefer-mux get-text --pane-id <pane_id> --start-line -300` で最近の出力を読む。
   - Claude Code のプロンプト（例: `C:\Users\kento\workspace\>` や `>` だけの行）が最後にあるか確認。
   - 既に別の作業中なら、その旨をユーザーに報告し、送信しない。

3. **指示を送信**
   - 指示の内容を明確にする。「Blender で新しいキューブを追加してください」など、具体的な指示。
   - テキスト本文を送信（上記のコマンド例を参照）。
   - Enter を送信（`[char]13` または `\r`）。

4. **応答を待って確認**
   - Claude Code が処理を開始するまで少し待つ（5秒程度）。
   - `get-text` で再度読み、応答が始まったか確認。
   - 長時間走るジョブなら、適切な間隔で状態を確認する（無計画な頻繁ポーリングは避ける）。
   - 明確な完了メッセージ（例: 「完了しました」「エラー:」）を確認してから、結果をユーザーに報告。

5. **結果をユーザーに報告**
   - Claude Code の応答をそのまま引用し、成功したか、エラーがあったかを明示。
   - 未検証の操作を成功扱いしない。

## MCP ツールの状態（2026-11-05 時点）

### Blender MCP
- **検出状態**: MCP ツールとして検出済み。
- **実通信**: 未検証。実際にシーンの操作が動くかは確認できていない。
- **利用時の注意**: 初回の指示では「Blender MCP を使って試してください」と明示し、結果を確認する。エラーが出たらユーザーに報告。

### After Effects MCP
- **検出状態**: MCP ツールとして検出済み。
- **実通信**: 新規空プロジェクトの情報取得で確認済み。基本的な通信は動く。
- **利用時の注意**: プロジェクトの保存、レンダリング、公開などはユーザー本人の承認が必要。

## WezTerm CLI の制約

- **pane 出力の継続 subscribe 機能はない**。公式ドキュメント上、pane の出力をリアルタイムにストリームする API は提供されていない。
- **代替案（未実装）**: WezTerm の Lua user-var-changed イベントと `pane:get_lines_as_text(scrollback_rows)` を用いて履歴ファイルに出力する方法がある。ただし、今回はこの Lua の追加設定を実装・テストしていないので、実証済みとは書かない。
- **ログの扱い**: WezTerm のログは GUI 本体のログであり、Claude Code の出力ログとして代替扱いしない。

## 実機での動作確認（Windows PowerShell 環境）

**日時**: 2026-11-05  
**環境**: SUGIMOTO-PC、wezterm 20251111-071056-118802c2

- 既存 mux に `blender` タブ（pane id 1）と `aftereffects` タブ（pane id 2）がある。
- 両方とも Claude Code が起動済みで入力待ち。
- `wezterm cli --prefer-mux list` で pane-id を確認。
- `wezterm cli --prefer-mux get-text --pane-id 1 --start-line -300` で現状確認。
- `$text | wezterm cli --prefer-mux send-text --pane-id 1 --no-paste` で本文を渡し、`[char]13 | wezterm cli --prefer-mux send-text --pane-id 1 --no-paste` で Enter を別に渡すと、実機で Claude への入力と応答取得が成功。

## エラーハンドリング

- **mux server が応答しない**: `wezterm-mux-server` プロセスが固まった可能性。ユーザーに報告し、mux server の再起動（プロセス終了）を提案。中のペインは消えるが、再度接続可能。
- **pane が見つからない**: pane 一覧を再取得し、ユーザーに確認を求める。
- **Claude Code が応答しない**: 長時間経っても応答がない場合、ユーザーに報告し、手動での確認を促す。
- **権限エラー**: MCP ツールの権限不足や、アプリが起動していない可能性。ユーザーに確認を促す。

## 他のスキルとの連携

- **obsidian-capture**: WezTerm 経由で Claude Code に作業を委譲した結果を、ノートに転記する際に使う。
- **daily-digest**: 毎朝の情報収集で、複数マシンの Claude Code に並行して指示を送る際に使える。
- **vst-study**: VST プラグインの調査結果を Blender や After Effects での制作に連携する際に使える。

## まとめ

このスキルは、Grok Bot から別のマシン上の Claude Code に作業を委譲し、MCP を使ったアプリ操作を連携するための橋渡しである。pane の選択、状態確認、指示の送信、応答の確認を慎重に行い、破壊的操作を避け、ユーザーの承認を得てから重要な操作を実行する。
