---
name: daily-digest
description: >-
  Gathers the last 24 hours of news for the user's interests (ボカロ, DTM,
  イラスト, AIエンジニア, Linux) from the curated sources in sources.md and
  writes one raw digest per day to digests/YYYY-MM-DD.md in the Obsidian
  vault, then links it from the daily note. Use when the user says 情報収集,
  今日のニュース, ダイジェスト, or for the scheduled morning run around 9:00
  JST. Never turn digest items into cards automatically.
---

# 情報収集

毎朝 9:00 ごろ（JST）に、前日からの約24時間の情報を集めて、ボルトに原本を1枚書く。書く前にボルトの `AGENTS.md` を読む。このスキルと違えば `AGENTS.md` に従う。

ボルトは次のいずれか。そこにあるファイルだけを編集する。

- Windows: `C:/Users/kento/notes`
- コンテナ: `/mnt/notes`
- Mac: `~/notes`
- Grok Bot: `/home/box/sync/obsidian-vault`（`~/notes` はここへのリンク）

情報源は、このスキルと同じフォルダの `sources.md` を読む。そこに無いサイトも使ってよいが、一次情報（公式ブログ、変更履歴、リリースノート）を優先する。

## 話題

- ボカロ: VOCALOID、歌声合成（VoiSona、Synthesizer V、UTAU など）、新曲、ランキング。
- DTM: 使っているプラグイン（Serum 2、Scaler、Melodyne、Splice、Kilohearts、Instacomposer、TAL、ZEN AUDIO など）のアップデートとセール、DAW の話題。
- イラスト: 描画ツール（CLIP STUDIO PAINT、Procreate、Krita など）、AI イラスト、イベント。
- AIエンジニア: モデルの発表、エージェントツール（Cursor、Claude Code、Codex など）、論文。
- Linux: Arch Linux、カーネル、Neovim、Ghostty、セキュリティ。

## 手順

1. `sources.md` と、ボルトの `digests/` にある直近7日ほどの原本を読む。
2. 話題ごとに、約24時間以内の項目を集める。日付が確かめられないものは入れない。ニュースと公式に加えて、`sources.md` の「SNS」の検索語で SNS の反応も見る（下の「SNS」）。
3. 直近の原本に同じ出来事があれば落とす。続報なら「続報」と書いて残す。
4. 話題ごとに3〜5件選ぶ。無ければ「目立った動きなし」と書く。
5. 各項目は、タイトル、日本語の要約1〜2文、出典リンク。要約は自分の言葉で書き、記事の文を写さない。
6. 次に当たる項目には `**重要**` を付ける。
   - 大きなリリース（メジャーバージョン、新モデル、新製品）
   - セキュリティの問題（CVE、悪性パッケージ、使っているツールの脆弱性）
   - ユーザーが使うツール（上の話題に挙げたもの、Arch、Neovim、Ghostty、Cursor、Obsidian、Syncthing）に影響する変更
   - 期限のあるセール、締め切りのあるイベント。期限を書く
7. 原本を書き、日次にリンクを足し、チャットで短く報告する。

## SNS

X、TikTok、YouTube、ニコニコ、pixiv、Reddit、Bluesky などの盛り上がりを拾う。使える手段と検索語は `sources.md` の「SNS」にある。ログインしない。ユーザーのアカウントは使わない。

- 盛り上がりとみなすのは、別々のアカウントから同じ話題の投稿が複数ある、または反応（いいね、リポスト、再生数、ランキング順位）が目立って多いときである。1件だけで反応も少ない投稿は入れない。宣伝、配信の告知、チケットの譲渡は入れない。
- 項目の頭に `SNS` と書き、投稿、動画、タグ、ランキングのページへリンクする。反応の数があれば添える（例: いいね 1.2万）。
- 公式や報道で確かめられない話は「未確認」と書き、断定しない。発表やセールの話は、公式のページを見つけて出典にする。
- 投稿の文を長く写さない。個人の投稿は、話題を示すのに要るものだけにする。
- 日本のトレンドに上の話題が出ていれば挙げる。

## 原本

パスは `digests/YYYY-MM-DD.md`。1日1枚。原本であり、カードではない。`notes/` には書かない。

同名のファイルがあるときは上書きしない。`digests/YYYY-MM-DD-2.md` のように番号を足して新規作成し、チャットで言う。

```yaml
---
type: digest
source: grok-bot
date: 2026-10-17
---
```

`source` は書いたエージェント（Grok Bot は `grok-bot`、Cursor は `cursor`）。本文は次の形にする。

```markdown
# 情報収集 2026-10-17

## 重要

- [タイトル](URL)（話題）: 一文。

## ボカロ

- [タイトル](URL): 要約。
- SNS [話題](投稿やタグの URL): 何が盛り上がっているか（反応の数）。
- **重要** [タイトル](URL): 要約。

## DTM

## イラスト

## AIエンジニア

## Linux
```

`## 重要` には、重要を付けた項目を再掲する。無ければ「なし」。

## 日次

その日の `daily/YYYY-MM-DD.md` の末尾にある `## 情報収集` に、次の1行を足す。

```markdown
- [[digests/YYYY-MM-DD|情報収集 YYYY-MM-DD]]
```

節が無いときは、ファイルの末尾に節ごと足す。同じ行がすでにあれば足さない。それ以外の行は書き換えない。日次ファイルが無いときは、`AGENTS.md` の「日次」のフロントマターで作る。`*.sync-conflict*` のファイルは読まず、触らない。日次に競合ファイルがあるときは、本体にだけ追記してチャットで言う。

## してはいけないこと

- 項目をカードにする。`notes/` に書く。ユーザーが特定の項目を残したいと言ったときだけ、`obsidian-capture` の手順で進める
- 記事の全文や長い引用を写す
- 既存の原本を上書きする、書き換える
- ログインする、ユーザーのアカウントを使う、ログインが要るページの中身を書く

## 報告

チャットでは、重要の項目をリンク付きで先に挙げ、話題ごとの件数と、原本へのパスを添える。数行に収める。
