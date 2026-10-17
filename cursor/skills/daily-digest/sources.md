# 情報収集の情報源

`daily-digest` が読む。一次情報を優先する。足すときは話題の節に1行で書く。

## ボカロ

- VOCALOID 公式ニュース: https://www.vocaloid.com/news/
- VoiSona 公式: https://voisona.com/ （お知らせ、X: @VoiSona_tss）
- Synthesizer V（Dreamtonics）: https://dreamtonics.com/news/
- クリプトン・フューチャー・メディア ピアプロブログ: https://blog.piapro.net/
- ニコニコ VOCALOID ランキング: https://www.nicovideo.jp/ranking/genre/music_sound （タグ VOCALOID）
- ボカコレ: https://vocaloid-collection.jp/
- ITmedia NEWS / 音楽: https://www.itmedia.co.jp/news/
- AV Watch: https://av.watch.impress.co.jp/

## DTM

- Xfer Records（Serum 2）: https://xferrecords.com/
- Scaler（Plugin Boutique）: https://www.scalerplugin.com/
- Celemony（Melodyne）: https://www.celemony.com/en/company/news
- Splice ブログ: https://splice.com/blog/
- Kilohearts: https://kilohearts.com/news
- TAL Software: https://tal-software.com/
- Plugin Boutique セール: https://www.pluginboutique.com/deals
- KVR Audio ニュース: https://www.kvraudio.com/news
- DTMステーション: https://www.dtmstation.com/
- Sleepfreaks: https://sleepfreaks-dtm.com/
- Gearspace: https://gearspace.com/board/new-product-alert/

## イラスト

- CLIP STUDIO PAINT お知らせ: https://www.clipstudio.net/ja/news/
- Procreate: https://procreate.com/
- Krita ニュース: https://krita.org/en/posts/
- pixiv inside: https://inside.pixiv.blog/
- コミックマーケット / COMITIA などイベント公式
- ITmedia AI+: https://www.itmedia.co.jp/aiplus/
- Gigazine: https://gigazine.net/

## AIエンジニア

- Cursor 変更履歴: https://cursor.com/changelog
- Anthropic ニュース / Claude Code 変更履歴: https://www.anthropic.com/news, https://github.com/anthropics/claude-code/releases
- OpenAI ニュース（Codex を含む）: https://openai.com/news/
- Google DeepMind / Gemini: https://blog.google/technology/ai/
- xAI ニュース: https://x.ai/news
- Hugging Face Papers: https://huggingface.co/papers
- arXiv cs.AI / cs.CL 新着: https://arxiv.org/list/cs.AI/new
- Simon Willison: https://simonwillison.net/
- Hacker News: https://news.ycombinator.com/
- Zenn トレンド: https://zenn.dev/
- Publickey: https://www.publickey1.jp/

## Linux

- Arch Linux ニュース: https://archlinux.org/news/ （手動介入が要る告知は重要）
- kernel.org: https://www.kernel.org/
- LWN.net: https://lwn.net/
- Phoronix: https://www.phoronix.com/
- Neovim リリース: https://github.com/neovim/neovim/releases
- Ghostty: https://ghostty.org/docs/install/release-notes
- Obsidian 変更履歴: https://obsidian.md/changelog/
- Syncthing リリース: https://github.com/syncthing/syncthing/releases
- OSS セキュリティ: https://www.openwall.com/lists/oss-security/
- Arch セキュリティ: https://security.archlinux.org/

## SNS

ログインしない。ユーザーのアカウントは使わない。2026-10-17 に Grok Bot のボックスから確かめた結果を書く。使えなくなったら書き直す。

### 使えるもの

- X（Grok Bot の X ツール）: 投稿の検索（`search_posts_all`、`public_metrics` 付き）と日本のトレンド（`get_trends_by_woeid`、WOEID `23424856`）。読める回数は1分30回、1日1000回まで。投稿の URL は `https://x.com/<user>/status/<id>`。
- YouTube 検索: `https://www.youtube.com/results?search_query=<語>&sp=CAI%253D`（新しい順）。HTML からタイトルを拾える。チャンネルの新着は `https://www.youtube.com/feeds/videos.xml?channel_id=<ID>`。
- ニコニコ: スナップショット検索 API `https://snapshot.search.nicovideo.jp/api/v2/snapshot/video/contents/search?q=VOCALOID&targets=tags&fields=contentId,title,viewCounter,startTime&_sort=-viewCounter&filters[startTime][gte]=<ISO日時>&_limit=10`。動画の URL は `https://www.nicovideo.jp/watch/<contentId>`。
- pixiv ランキング: `https://www.pixiv.net/ranking.php?mode=daily&content=illust&format=json`。作品の URL は `https://www.pixiv.net/artworks/<illust_id>`。
- Bluesky: `https://api.bsky.app/xrpc/app.bsky.feed.searchPosts?q=<語>&sort=top&limit=25`（`public.api.bsky.app` は 403）。
- Hacker News: `https://hn.algolia.com/api/v1/search?tags=front_page`、`https://hn.algolia.com/api/v1/search_by_date?query=<語>&tags=story`。
- Web 検索の `site:x.com`、`site:tiktok.com`、`site:reddit.com`: 補助として使える。日付と数字は元のページで確かめる。

### 使えないもの

- Reddit: `www.reddit.com` の `.json` と `.rss` は 403、`old.reddit.com` はリダイレクトで中身が出ない。Web 検索の `site:reddit.com/r/<sub>` で代える。
- TikTok: タグのページ（`https://www.tiktok.com/tag/<タグ>`）は開けるが、動画の一覧は JavaScript で出るので拾えない。Creative Center のトレンドも同じ。Web 検索の `site:tiktok.com #<タグ>` と、TikTok の流行を報じるニュースで代える。
- nitter 系のミラー: `nitter.net` は開けるが検索結果が空、`xcancel.com` は 451、`nitter.privacydev.net` はつながらない。X ツールを使う。

### 話題ごとの検索語

| 話題 | X | ほか |
| --- | --- | --- |
| ボカロ | `#ボカロ`、`#VOCALOID`、`#初音ミク`、`#VoiSona`、`#SynthV`、`#重音テト`、`#ボカコレ`、`#vocaloid` | ニコニコ（タグ VOCALOID、24時間）、YouTube「ボカロ 新曲」、TikTok `#ボカロ` |
| DTM | `#DTM`、`#Serum2`、`#Melodyne`、`#Splice`、`#作曲`、`#musicproduction`、`#producer` | YouTube「Serum 2」、Reddit r/edmproduction・r/WeAreTheMusicMakers（Web 検索で）、TikTok `#DTM` |
| イラスト | `#イラスト`、`#絵描きさんと繋がりたい`、`#クリスタ`、`#AIイラスト`、`#illustration`、`#procreate` | pixiv デイリーランキング、TikTok `#イラストメイキング` |
| AIエンジニア | `Cursor`、`"Claude Code"`、`Codex`、`#生成AI`、`#LLM`、`#AIエージェント` | Hacker News、Bluesky、Reddit r/LocalLLaMA・r/ClaudeAI（Web 検索で） |
| Linux | `"Arch Linux"`、`#archlinux`、`Neovim`、`Ghostty`、`#Linux` | Hacker News、Bluesky、Reddit r/archlinux・r/neovim（Web 検索で） |

X では、検索語に `-is:retweet` を付け、日本語は `lang:ja` を付け、`start_time` を24時間前にし、`sort_order: relevancy` で取る。
