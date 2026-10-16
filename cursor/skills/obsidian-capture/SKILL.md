---
name: obsidian-capture
description: >-
  Saves chat content the user wants to keep into the Obsidian vault as one
  claim per note, and groups inbox notes into KJ maps. Use when the user says
  メモして, 残して, ノートに書いて, 島にして, KJして, or asks to capture,
  transcribe, or file a conversation into Obsidian.
---

# Obsidian への転記

Cursor からボルトへ書くときの入口である。書く前にボルトの `AGENTS.md` を読み、その手順で書く。このスキルと違えば `AGENTS.md` に従う。

ボルトは次のいずれか。そこにあるファイルだけを編集する。

- Windows: `C:/Users/kento/notes`
- コンテナ: `/mnt/notes`
- Mac: `~/notes`

`source` は `cursor`。カードはファイルとして書く。貼り付け用のフェンスは返さない。

## カードを足す

きっかけは「メモして」「残して」「ノートに書いて」。カードを足すだけにする。既存ノートの移動、改名、タグの付け替えはしない。

1. 残す範囲を、1主張につき1枚に分ける。複数あるときは、書く前にタイトル一覧をチャットへ出す。
2. `notes/<主張を短くした日本語>.md` を作る。`\ / : * ? " < > |` は `-` にする。同名があるときは上書きせず、ファイル名の末尾に日付を足し、チャットに両方の名前を出す。
3. その日の `daily/YYYY-MM-DD.md` 末尾の `## チャットから` に `- [[主張]]` を1行足す。節が無ければ末尾に節ごと足す。他の行は書き換えない。日次が無いときだけ、`AGENTS.md` のフロントマターで作る。
4. `*.sync-conflict*` は削除もマージもしない。秘密鍵、トークン、認証情報、会話の写しは書かない。

```yaml
---
type: capture
status: inbox
source: cursor
captured: YYYY-MM-DD
---
```

本文は `## 残すこと`、`## 根拠`、`## つながり` だけ。根拠の推測は推測と書く。つながりは既存ノートへの `[[リンク]]`、無ければ空。`captured` はその日の日付であり、`{{date}}` とは書かない。

## 島にする

きっかけは「島にして」「KJして」。`status: inbox` のカードを読み、`maps/<表札>.md` を1枚書く。カードのファイルは動かさず、`status` だけ `clustered` にする。キャンバスは書かない。

```yaml
---
type: map
status: draft
---
```

島ごとに、見出し、意味を一文、カードへのリンクを書く。
