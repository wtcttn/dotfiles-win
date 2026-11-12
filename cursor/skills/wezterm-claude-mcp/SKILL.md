---
name: wezterm-claude-mcp
description: >-
  Connect from Grok Bot to Claude Code running in existing WezTerm mux
  sessions on SUGIMOTO-PC or other machines, to delegate MCP-driven work
  (blender-mcp, after-effects MCP, studio-one, fal.ai) to Claude running
  closer to the application. Each app's MCP lives only in the pane started
  in its folder (cg, music, media-gen); see grokbot/claude-code.md. Use when the user asks to send a task to Claude on a
  specific machine, control Blender/After Effects through Claude, or
  orchestrate multi-machine creative workflows.
---

# WezTerm mux 経由の Claude Code への連携

**2026-11-12 から、ふだんの依頼はスキル `hub-bridge`（MCP サーバー `hub-bridge` の `send_to_hub`）で `hub` に送る。このスキルは予備で、hub が閉じていて `hub-bridge` に `ping` が届かないときだけ使う。** 401 や「HTTP 404 で読み込みに失敗」のような設定の問題では、このスキルに切り替えず、オーナーに報告する。

Grok Bot から、SUGIMOTO-PC など別のマシン上の WezTerm mux セッションで既に起動している Claude Code に指示を送るスキルである。Blender MCP や After Effects MCP など、アプリに近い Claude が持つツールを使った制作に連携する。

## 原則

- **機械固有情報をハードコードしない**。pane id や端末名は実行時に `wezterm cli --prefer-mux list` で取得し、ユーザーが指示した作業に合う pane を選ぶ。
- **全 Bot で汎用的に使える**。Windows PowerShell、Linux bash、macOS zsh でのコマンド例を記載し、環境ごとに分岐する。
- **既存の作業を止めない**。送信前に必ず現在の画面を読み、入力欄が空か、Claude が入力待ち状態であることを確認する。意図した pane であることも確認する。
- **明確な完了確認をする**。応答は `get-text` で読み、明確な完了確認のない状態を完了扱いしない。長時間走るジョブは無計画にポーリングせず、必要な場面で状態を見る。
- **破壊的操作をしない**。`spawn` は使わない（現在の nightly では外部 spawn が mux server を固める問題があり、大量タブ発生の原因）。ペインが足りないときは、hub に頼む（hub は mux の中から `ccs` で立ち上げる。2026-11-12 に、mux の中からの spawn では固まらないことを確かめた）。`kill`、`split` 等の破壊的・構造変更コマンドも明示依頼なしに行わない。
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

## 依頼の取り決め

依頼の印、Claude Code がすること・しないこと、終わりの合図は、dotfiles の `grokbot/claude-code.md` が正本である。送る前に読む。要点は次のとおり。

- 依頼は1行にする（改行は送信になる）。長い指示はファイルに置き、パスを渡す。
- 先頭に `[Grok Bot / 依頼元: <Bot 名> / 正本: <読むファイル> / 書いてよい場所: <パスか なし>]` を付ける。
- Claude Code は最後の行を `完了: …` か `エラー: …` で締める。この行が出るまで完了扱いしない。
- Claude Code はボルトに書かない。ノートに残す結果は、ノート管理に頼む。
- ボルトは Syncthing の同期に1分ほどかかる。ノート管理に書いてもらった直後にその内容を読ませるときは、印に `ボルト更新: <パス> <更新時刻>` を付けるか、1分ほど置いてから送る。

## 実行手順

1. **pane の特定**
   - `wezterm cli --prefer-mux list` で pane 一覧を取得。
   - タブ名と cwd から、`grokbot/claude-code.md` の「ペインの割り当て」に合うペインを探す。Blender は `blender`、After Effects は `aftereffects` のタブ（どちらも cwd が `workspace\cg`）、Studio One・Suno・効果音は `music`、画像・動画の生成は `media-gen`。制作ごとの取りまとめのペイン（`research` など）がある制作では、そこへ送る。大きいファイルは制作フォルダの `inbox\` に置き、パスだけを送る。アプリの MCP はそのフォルダで起動した Claude Code にしか無い。
   - 合うペインが無ければ送らず、どのフォルダで Claude Code を起動してほしいかをユーザーに伝える（`spawn` はしない）。
   - pane_id を記録する。

2. **現在の状態を確認**
   - `wezterm cli --prefer-mux get-text --pane-id <pane_id> --start-line -300` で最近の出力を読む。
   - Claude Code のプロンプト（例: `C:\Users\kento\workspace\>` や `>` だけの行）が最後にあるか確認。
   - 既に別の作業中なら、その旨をユーザーに報告し、送信しない。

3. **指示を送信**
   - 指示の内容を明確にする。「Blender で新しいキューブを追加してください」など、具体的な指示。
   - 先頭に `grokbot/claude-code.md` の印を付け、1行にする。
   - テキスト本文を送信（上記のコマンド例を参照）。
   - Enter を送信（`[char]13` または `\r`）。

4. **応答を待って確認**
   - Claude Code が処理を開始するまで少し待つ（5秒程度）。
   - `get-text` で再度読み、応答が始まったか確認。
   - 長時間走るジョブなら、適切な間隔で状態を確認する（無計画な頻繁ポーリングは避ける）。
   - 最後の行の `完了:` か `エラー:` を確認してから、結果をユーザーに報告。

5. **結果をユーザーに報告**
   - Claude Code の応答をそのまま引用し、成功したか、エラーがあったかを明示。
   - 未検証の操作を成功扱いしない。

## MCP ツールの状態（2026-11-06 時点）

どの MCP がどのペイン（フォルダ）にあるかは `grokbot/claude-code.md` の「ペインの割り当て」を見る。

### Blender MCP（`cg` ペイン）
- **中身**: 公式の Blender Lab MCP（`blender`、ポート 9877）と、コミュニティ版の mcp-for-blender（`blender-community`、ポート 9876。Poly Haven と Tripo）。Blender 5.2。
- **実通信**: 2026-11-06 に両方で確認済み（シーンの読み取り、アドオンの状態）。
- **利用時の注意**: Tripo の生成は API クレジットを使うので、ユーザー本人の承認が要る。

### fal.ai MCP（`media-gen` ペイン）
- **中身**: fal.ai 公式のホスト型 MCP（`https://mcp.fal.ai/mcp-relay`）。ログインはオーナーがブラウザで行う。
- **利用時の注意**: 生成のたびに課金される。枚数か上限額の承認を依頼文に入れる。

### After Effects MCP（`cg` ペイン）
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
