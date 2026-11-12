---
name: task-board
description: >-
  Rebuilds the Obsidian Kanban boards (boards/全体.md and boards/オーナー.md)
  from the one-note-per-task files in tasks/, after first writing the owner's
  card moves on boards/オーナー.md back to each note's status and turning new
  owner cards into task notes. Run by Grok Bot's ノート管理 on its schedule,
  or when the owner says ボードを更新して, タスクボード, カンバンを更新.
  Uses the bundled sync_boards.py; never hand-edit boards/全体.md.
---

# タスクのボードの作り直し

Grok Bot の「ノート管理」が定期に行う作業である。決まりの正本は、ボルトの `AGENTS.md` の「タスク」の節。このスキルと違えば `AGENTS.md` に従い、このスキルとスクリプトを直す依頼をオーナーに出す。

ボルトは次のいずれか。

- Windows: `C:/Users/kento/notes`
- コンテナ: `/mnt/notes`
- Mac: `~/notes`
- Grok Bot: `/home/box/sync/obsidian-vault`（`~/notes` はここへのリンク）

## どこで動かすか（2026-11-12 から）

- `sync_boards.py` は、いつもボックス（ボルトの控え `/home/box/sync/obsidian-vault`）で動かす。PC の `C:\Users\kento\notes` では動かさない。PC で動かすと `~/notes` の外の Python を使うので、Grok Bot のデスクトップアプリの Auto-review のルール（`~/notes` の中の読み書きだけを確認なしで通す）の外になる。
- ノート管理はふだん PC のボルトに直接書くので、ボックスの控えは同期で遅れていることがある（ボックスと kento-server の間の同期は、黙って止まることがある）。動かす前と後に、ボックスの Syncthing で `notes` フォルダの同期が 100% か確かめる。
  - 前: ボックスの `notes` が idle で、取り込み待ち（needFiles など）が 0。あわせて、kento-server から見た完了度（`/rest/db/completion`）が 100%。
  - 後: 書いたボードとノートが kento-server に届き、完了度が 100% に戻る。
  - そろわなければ、その回は動かさずに飛ばし（動かしたあとなら、そろうまで待って結果を見る）、「同期がそろわないので飛ばした」と報告する。次の回にもう一度確かめる。

## 手順

1. 上の「どこで動かすか」の前の確かめをしてから、このスキルのフォルダにある `sync_boards.py` を動かす。Python 3 の標準ライブラリだけで動く。

   ```sh
   python3 <このスキルのフォルダ>/sync_boards.py --vault <ボルト>
   ```

   何が起きるか先に見たいときは `--dry-run` を付ける。書かずに、同じ報告を出す。

2. 標準出力の JSON を読む。
   - `status_updates`: オーナーがボードで動かし、ノートの `status` に書き戻したもの
   - `created`: オーナーがボードに書き足したカードから作ったノート
   - `boards_written`: 作り直したボード
   - `warnings`: 下の「知らせること」
   - `stopped`: 止めた理由（終了コード 2）

3. 後の確かめ（同期が 100% に戻ったか）をする。

4. 報告する。変化が無い回（`status_updates`・`created`・`warnings` がどれも空）は、報告しなくてよい。同期がそろわずに飛ばした回は、必ず報告する。

## 知らせること

次はオーナーに一言で知らせる。自分で直さない。

- `stopped` が同期の衝突（`*.sync-conflict*`）のとき。衝突ファイルは消さない、まとめない。
- `stopped` が「直前に変わった」のときは知らせず、次の回にもう一度動かす。続けて3回止まったら知らせる。
- `unknown_columns`: オーナーのボードに、決まりに無い列がある。その列のカードは読んでいない。
- `missing_note`: ボードのリンク先のノートが無い（名前を変えた、消したなど）。
- `not_owner_task_on_owner_board`: 担当がオーナーでないタスクが、オーナーのボードに置かれた。状態は変えていない。
- `unknown_status`: ノートの `status` が5つのどれでもない。どの列にも載っていない。
- `cannot_create`: 新しいカードと同じ名前のノートがあり、作れなかった。

## しないこと

- `boards/全体.md` を手で書き換えない。スクリプトで作り直す。
- オーナー担当のタスクの `status` を、ボードを通さずに変えない。
- タスクのノートを消したり動かしたりしない。
- スクリプトが止まったときに、手でボードを組み立てない。
