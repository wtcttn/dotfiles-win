# Grok Bot から Claude Code への依頼

Grok Bot と、オーナーの PC で動く Claude Code のあいだの取り決めの正本である。両方がこれを読む。Grok Bot が送る手順はスキル `hub-bridge`、hub がいないときに用意する手順はスキル `hub-keeper`、マーケターが調査を直接呼ぶ手順はスキル `research-request`、Claude Code の入口は `claude/CLAUDE.md`（`~/.claude/CLAUDE.md`）にある。

## 役割

Claude Code は、オーナーの PC 上の手である。PC にしか無いもの（Chrome のログイン状態、Studio One、After Effects、Blender、ローカルのファイル）を使う作業を受ける。実装やリポジトリの作業は、これまでどおり Cursor のクラウドエージェントに任せる。

## ペインの割り当て

アプリを動かす MCP は、決まったフォルダで起動した Claude Code にだけ入っている。MCP の定義はそのフォルダの `.mcp.json`（project スコープ）で、正本は dotfiles の `claude/workspaces/<フォルダ名>/`（2026-11-10 から。それまでは `claude mcp` の local スコープ）。ほかのペインからは、アプリにも課金のある生成にも触れない。Grok Bot は、依頼に合うペインへ送る。

### 常駐ペイン（固定）

| ペイン（タブ名・セッション名） | 起動したフォルダ | 起動のしかた | 使える MCP | 送る依頼 |
| --- | --- | --- | --- | --- |
| `hub` | `C:\Users\kento\workspace\hub` | `cc hub` | bitwarden | オーナーの右腕。依頼の窓口、各ペインへの振り分けと取りまとめ、制作フォルダの整備、調べもの |
| `blender` | `C:\Users\kento\workspace\cg` | `cc blender` | blender、blender-community、after-effects | Blender、3D 素材 |
| `aftereffects` | `C:\Users\kento\workspace\cg` | `cc aftereffects` | 同上 | After Effects、合成、字幕、書き出し |
| `music` | `C:\Users\kento\workspace\music` | `cc music` | studio-one、splice、musio-studio、suno、myinstants | Studio One、BGM（Suno）、効果音、声、ミックス |
| `media-gen` | `C:\Users\kento\workspace\media-gen` | `cc media-gen` | fal | 画像・動画の生成（課金あり） |

- 固定のペインは、WezTerm の mux（ランチャの「PowerShell (常駐)」）で `cc <名前>` から起動する。`cc` は dotfiles の PowerShell プロファイルにあり、表のフォルダに移り、要る秘密を Bitwarden から読んでこのペインにだけ渡し（`claude/workspaces/<フォルダ>/secrets.bw`）、`claude -n <名前>` を起動する。フォルダが違うと MCP が入らない。
- どのペインがどのフォルダかは、`wezterm cli --prefer-mux list` の cwd とタブ名で確かめる。cwd が表と違うペインには、アプリの依頼を送らない。
- 各フォルダの `CLAUDE.md` に、そのアプリの癖と、承認の要る操作が書いてある。
- どこへ送ればよいか迷う依頼、複数のペインにまたがる依頼は `hub` に送る。

### その都度のペイン

制作ごとに、固定のペインのほかにペインを足してよい（例: アニメ担当の `blender-anim`）。足すのはオーナーか、オーナーに確かめた `hub` である。

- 名前は役割がわかる短い英小文字にし、`cc <名前> <フォルダ>` で起動する（例: `cc blender-anim cg`）。タブ名とセッション名がそろう。
- mux に立ち上げるときは `ccs <名前> [<フォルダ>]`（PowerShell のプロファイル）。同じタブ名のペインがあれば何もしない。hub は常駐していて、頼みたいペインが無ければ `ccs` で立ち上げる（固定のペインは hub の判断で、制作ごとのペインはオーナーに確かめてから）。hub 自身は `Start-Hub` で立ち上げる。
- アプリの MCP が要るなら、上の表のフォルダで起動する。
- 制作の取りまとめは、ふだんは `hub` が行う。Grok Bot の依頼は `hub` へ送り、`hub` が各ペインへ `SendMessage` で振り分ける。取りまとめを別のペインに任せる制作では、制作フォルダの `README.md` にそのペインを書く。
- 制作が終わったら、オーナーが閉じる。
- 頼まれた作業に要る MCP がそのペインに無いときは、Claude Code は手を付けずに `エラー: このペインに <MCP 名> が無い（<フォルダ> のペインに送る）` で締める。
- ペインを増やす、別のフォルダで起動し直すのは、オーナーか hub が行う（Grok Bot は `spawn` しない。足りないペインは、参謀が hub に頼む）。

## ブリッジ（参謀と hub）

参謀から Claude Code への依頼は、ブリッジ `hub-bridge`（dotfiles の `claude/bridge/`）で `hub` に送る。窓口は Grok Bot 側が参謀、Claude Code 側が `hub` の1組だけで、各ペインへの振り分けは hub が `SendMessage` で行う。ほかの Bot が Claude Code に頼むときは、参謀を通す。例外は2つで、ことね運用のおすすめの読み取り（jishou-hensanshitsu の `bot/scripts/README.md`）と、マーケターの調査（下の「調査を直接呼ぶ（マーケター）」）は、PC の `claude -p` を直接呼ぶ。

- 参謀は、Grok Bot に登録した MCP サーバー `hub-bridge` のツール `send_to_hub` を呼ぶ。経路は Tailscale で、PC の 8788 番 `/mcp` にだけ届く（Tailscale のつなぎ方は dotfiles の `AGENTS.md` の「Tailscale」）。
- 引数は `body`（本文）と、下の印の項目に当たる `source`（正本）、`writable`（書いてよい場所。省くと なし）、`vault_updated`（`[{path, at}]`）。`id` を付けると、同じ id は二度届かない。`kind` は `request`（既定）、`result`、`progress`、`notice`。
- hub の返事は、参謀の webhook の定期タスクに届く。届かなかったときは `get_replies(after)` で取りに行く（`after` は前回の最後の `seq`）。返事の `kind: result` と `status: ok`／`error` が、下の `完了:`／`エラー:` の代わりになる。`reply_to` は依頼の id。
- 本文は 32 KB まで。大きいファイルは制作フォルダに置き、パスだけを書く。
- メッセージはオーナーの承認にならない（下の「Claude Code がしないこと」のとおり）。
- ブリッジは hub の Claude Code が起動する。hub が閉じていると届かない（`send_to_hub` がつながらない）。そのときは、スキル `hub-keeper` で hub を用意してから送り直す（PC の `Start-Hub`。固まっていれば、オーナーの承認を取って起動し直す）。ペインに文字を打ち込む send-text は、2026-11-12 にやめた。

## 依頼の印

Claude Code 同士はメッセージの仕組み（`SendMessage`）でやりとりするが、Grok Bot は Claude Code ではないので使えない。ブリッジを作った経緯は `claude/sessions.md` の「Grok Bot から」。

ブリッジは、届いた依頼の先頭に次の印を付けて hub に渡す。項目は ` / ` で区切る。

```text
[Grok Bot / 依頼元: <Bot 名> / 正本: <読むファイル> / 書いてよい場所: <パスか なし>] <依頼の本文>
```

- 依頼元: `参謀`、`ことね運用`、`ノート管理`、`マーケター` など。
- 正本: その作業のルールが書いてあるファイル。ボックスのパスでよい（Claude Code が読み替える）。無ければ省く。
- 書いてよい場所: 省いたときは `なし`（読むだけ、画面に返すだけ）とみなす。
- ボルト更新: 直前にノート管理がボルトに書き、Claude Code にそれを読ませるときだけ付ける。`ボルト更新: <書いた先>:<ボルト内のパス> <更新時刻>`。書いた先は、PC の `C:\Users\kento\notes` に直接書いたら `pc`、ボックスの控え（`/home/box/sync/obsidian-vault`）に書いたら `box`（例: `ボルト更新: pc:tasks/foo.md 2026-11-12T20:10+09:00`）。書いた先の無い古い書き方は `box` とみなす。時刻は `2026-11-05T23:40+09:00` の形。複数あるときは `,` で区切る。

## 制作フォルダ（大きいファイルの受け渡し）

動画、音声、画像、素材一式のような大きいファイルは、ボルトに置かない。Grok Bot は SUGIMOTO-PC のファイルを読めるので、制作フォルダに置いてパスで伝える（2026-11-10 から）。

場所は `C:\Users\kento\workspace\productions\<作業名>\`。作業名は英小文字とアンダースコア（例: `exitquiz_s4s9`）。中身は次のとおりで、ほかのフォルダ（`audio\`、`blender\`、`edit\`、`deliver\` など）は制作ごとに決めてよい。

| 置くもの | 書く人 | 中身 |
| --- | --- | --- |
| `README.md` | Claude Code（取りまとめ） | 正本（台本など）、仕様、フォルダの割り当て、承認の範囲、取りまとめのペイン |
| `inbox\` | Grok Bot | Grok Bot からの依頼文（`request_NN.md`）と、取り寄せた素材（`inbox\<日付>_<中身>\`） |
| `outbox\` | Claude Code | Grok Bot への依頼文（`request_NN.md`）と、納品・引き継ぎ（`handoff_NN_<中身>.md`） |

- 依頼の1行には、ファイルのパスだけを書く（例: `… 正本: C:\Users\kento\workspace\productions\exitquiz_s4s9\inbox\request_02.md`）。
- 素材を `inbox\` に置いたら、Grok Bot はファイル数かハッシュの一覧を添える。Claude Code は受け取ったら照合し、結果を返す。
- `outbox\` の引き継ぎには、完成物のパス、クレジット、出どころ、公開前に決めてほしいこと、直しの頼み方を書く。
- どちらも、相手の書いた同じ名前のファイルを上書きしない。直すときは番号を上げる。
- ボルトには、ノートに残す要点とパスだけを書く（書くのはノート管理）。
- 2026-11-10 より前の制作（`C:\Users\kento\research\minecraft-style\exitquiz_s4s9\` など）は、そのままの場所に置いておく。

### 制作の決まりと道具（正本は production-kit）

制作の決まり（仮組みを見てから本番を描く順番、描画・音・素材・公開の決まり）、共通の道具、制作フォルダの雛形の正本は、非公開リポジトリ `wtcttn/production-kit`（`C:\Users\kento\workspace\wtcttn\production-kit`）にある。決まりは `RULES.md` を読む。新しい制作フォルダは、その `new-production.ps1` で雛形から作る。

## 調査を直接呼ぶ（マーケター）

2026-11-12 のオーナーの決定。Grok Bot の「マーケター」は、調査と分析の担当である。調べものは、マーケターが SUGIMOTO-PC の Claude Code を直接呼んで行う。hub と hub-bridge は通さない。形は、ことね運用のおすすめの読み取り（`C:\Users\kento\kotone-foryou`）と同じで、作業フォルダに移って `claude -p` を動かし、長いものは裏で動かして終わりの印のファイルを待つ。手順はスキル `research-request`、呼ばれた Claude Code の決まりは `claude/workspaces/research/CLAUDE.md` にある。

### 作業フォルダ

調査のたびに `C:\Users\kento\workspace\research\<YYYYMMDD>_<題名>\` を作る（題名は英小文字とアンダースコア。例: `20261112_shorts_trend`）。

| 置くもの | 書く人 | 中身 |
| --- | --- | --- |
| `request_NN.md` | マーケター | 目的、問い（1〜3）、範囲、締め切り、出力の形、禁止事項。雛形は dotfiles の `claude/workspaces/research/templates/request.md` |
| `report_NN.md` | Claude Code | 要点3行、確かなことと推測を分けた本文、出典の URL と確かめた日時。雛形は同じフォルダの `report.md` |
| `sources\` | Claude Code | 集めた資料の写し |
| `session_NN.txt`、`prompt_NN.txt`、`run_NN.log`、`run_NN.err`、`cleanup_NN.txt`・`cleanup_NN.log`、`report_NN.done` | 起動スクリプト | 会話の ID と起動したプロセス、渡した指示、最後の返事、エラー、Chrome の後始末、終わりの印 |

- 番号 `NN` は `01` から。追加の問いややり直しは、番号を上げた `request_NN.md` で頼む。相手の書いたファイルは書き換えない。
- 結果はボルトの inbox に入れない。作業フォルダに置いたまま、パスだけを受け渡す。Claude Code はボルトに書かない。ノートに残すものは、マーケターが要点とパスをノート管理に頼む。

### 呼び方

Grok Bot のデスクトップアプリで SUGIMOTO-PC を指定し、PowerShell で起動スクリプトを動かす。

```powershell
& "$env:USERPROFILE\dotfiles\claude\workspaces\research\run-research.ps1" -Dir C:\Users\kento\workspace\research\20261112_shorts_trend -N 01 -MaxMinutes 60 -Background
```

- `-Background` は裏で動かしてすぐ戻る。`report_NN.done` ができたら終わり。1行目が `done 0` なら成功、`done <0 以外>` は失敗、`timeout` は打ち切り（`report_NN.md` があれば途中までの結果）、`abandoned` は起動スクリプトが外から止められ、次の起動のときに片付けたもの。2行目以降に `report:`（あり／なし）、`tabs:`（Chrome の後始末）、`session:`（会話の ID）がある。1〜2分おきに見て、`-MaxMinutes` に10分を足しても無ければ、オーナーに知らせる。短いもの（10分ほどまで）は `-Background` を付けずに待ってよい。
- 起動スクリプトは、作業フォルダに移り、`claude -p --chrome` を、Chrome と WebSearch・WebFetch・読み取りと、作業フォルダの中の書き込みだけを許して動かす。`-MaxMinutes`（既定60、5〜300）で打ち切る。Chrome が要らない調査は `-NoChrome`。
- PC のコマンドには、Grok Bot の自動の安全確認（Auto-review）が入る。止められたときは、オーナーの承認カードを待つ。許可のルールは、この取り決めでは変えない。

### Chrome

- ログイン中の Chrome（Claude in Chrome）を使う。読むだけにする。投稿、返信、いいね、リポスト、フォロー、ブックマーク、購入・課金、設定の変更、フォームの送信はしない。
- ことねの巡回（おすすめの読み取り）も同じ Chrome を使うが、並列で動かしてよい（2026-11-12 オーナー決定）。時刻をずらしたり、使用中の印を置いたりしない。
- タブは調査のタブグループの中だけで使い、終わる前にすべて閉じる（最初に作られる空のタブも）。オーナーのタブは触らない。
- 後始末: Chrome を使った調査が終わったら、正常終了でも打ち切り（`timeout`）でも、起動スクリプトが同じ会話（`--session-id` で決めた ID）を `claude -p --resume` で再開し、その会話のタブグループに残ったタブをすべて閉じる（最後のタブを閉じるとグループも消える）。Claude in Chrome から見えるのは自分の会話のグループだけなので、ことねの巡回やオーナーのタブ、ほかの調査のグループには届かない。結果は `report_NN.done` の `tabs: tabs-before: <数> tabs-after: <数>` の行に出る。`tabs-after` が 0 でない、または確かめられないと書いてあれば、オーナーに知らせる。後始末は上限 90 秒（ふだんは 10 秒ほど）。
- 起動スクリプトそのものが外から止められると、その場では後始末できない。そのときは、次に起動スクリプトを動かしたとき（どの作業フォルダでも）、`session_NN.txt` があって `report_NN.done` が無く、記録したプロセスがもういない調査を見つけ、同じように後始末してから `report_NN.done` を `abandoned` で書く。

## ボルトの同期の遅れ

2026-11-12 から、ボルトの書き込みの主な経路は次のとおり（オーナーの決定。細かいところはボルトの `AGENTS.md` が正）。

- ノート管理は、SUGIMOTO-PC の `C:\Users\kento\notes` に、Grok Bot のデスクトップアプリから直接書く。読み書きだけで、削除はしない。削除・名前の変更・移動は、オーナーに確かめてから PC で承認カードを通して行う。
- PC がオフのときだけ、ボックスの控え（`/home/box/sync/obsidian-vault`）に書き、Syncthing（ボックス → kento-server → PC）で届くのを待つ。ボックスと kento-server の間の同期は、黙って止まることがある（2026-11-12 に2回、7〜11 分止まった）。
- hub と、Grok Bot に呼ばれた Claude Code はボルトに書かない（今までどおり）。

Claude Code の読み方:

- `ボルト更新: pc:…` は、PC に直接書かれている。待たずにすぐ読む。
- `ボルト更新: box:…`（書いた先の無い古い書き方も）は、Syncthing で届くのを待つ。ファイルの更新時刻がその時刻より前なら（Syncthing は元の更新時刻を運ぶ）、まだ届いていない。1分ほどおきに見直す。決まった時間で打ち切って未同期のエラーにはしないが、古い内容のまま進めない。5分ほどたっても届かなければ、待っていることと、届いていないパスを参謀に知らせる（hub はブリッジの `progress`）。同期の止まりを調べるのは、参謀に頼まれたときだけ（見るだけ）。
- 同じ名前の `*.sync-conflict*` があれば、どちらが正しいか決めずに `エラー:` で知らせる。消したりマージしたりしない。
- 逆向き: PC がオンなら、Grok Bot は PC の `C:\Users\kento\notes` を直接読む（同期を待たない）。ボックスの控えは、同期の遅れで古いことがある。

例:

```text
[Grok Bot / 依頼元: 参謀 / 正本: /home/box/repos/my-mv-conte-tools/AGENT.md / 書いてよい場所: なし] After Effects で開いているコンポの名前と長さを教えてください
```

## Claude Code がすること

1. 印に `ボルト更新:` があれば、上の「ボルトの同期の遅れ」のとおり読む（`pc:` はすぐ、`box:` は届いたのを確かめてから）。
2. 印の正本と、`claude/CLAUDE.md` の正本のうち関係するものを読む。パスはこの PC のものに読み替える。
3. 依頼の範囲だけを行う。書いてよい場所の外は変更しない。
4. hub は、ブリッジの `reply` で結果を返す（`kind: result`、`status: ok` か `error`、`reply_to` に依頼の id）。参謀はこれを見て終わったと判断する。hub が各ペインに振り分けたときは、ペインの報告をまとめてから返す。マーケターに直接呼ばれた調査は、`report_NN.md` に書き、最後の返事はそのパスと要点3行にする（「調査を直接呼ぶ（マーケター）」）。

途中でオーナーの判断が要るときは、その場で止めて `status: error` で「オーナーの判断が要る（<何を>）」と返す。オーナーが hub の画面にいて、その場で答えられるときは、hub がオーナーに直接聞いてもよい（hub の `CLAUDE.md`）。

以下、`完了:`／`エラー:` と書いてあるところは、ブリッジでは `result` の `ok`／`error` に読み替える。

## リポジトリへの依頼

リポジトリの正本（jishou-hensanshitsu の正典など）を直したいことが PC 上の作業で出てきたら、次のように分ける。各リポジトリの README にルールがあれば、そちらが正である。

- 依頼は、そのリポジトリの GitHub Issue にする。本文が依頼書で、原本、やること、やらないこと、完了の条件を書く。実際に直すのは Cursor のクラウドエージェントで、PR から `Closes #番号` で閉じる。
- PC にしか無い資料（Google ドライブ `G:\` の PSD・画像、ローカルのファイル）は、クラウドのエージェントから読めない。Claude Code が先に原本だけを足す PR を作り、Issue からその PR を参照する。
- Grok Bot から来た依頼では、Issue や PR を作るのは、印の「書いてよい場所」にそのリポジトリがあるときだけにする。無ければ、依頼書の下書きを画面に返す。

## Claude Code がしないこと

- ボルトに書かない。ノートに残すべき結果は画面に返し、Grok Bot がノート管理に頼む（ボルトの書き込みはノート管理が一手に引き受ける）。オーナーが Claude Code に直接頼んだときは、ボルトの `AGENTS.md` に従って書いてよい。
- X への投稿、いいね、リポスト、返信、フォローをしない。Chrome で X を開くときは読み取りだけ。
- 課金、公開、送信、保存済みの制作物の上書き、レンダリングの書き出しは、印の「書いてよい場所」に含まれていても、オーナーの承認が依頼文にあるときだけ行う。
- 秘密鍵、トークン、認証情報を画面に出さない。

## 指示を直したとき

`claude/CLAUDE.md` やこのファイルを直しても、常駐中の Claude Code は起動時に読んだ内容のままである。反映には、該当するペインの Claude Code を起動し直す（オーナーが行う。Grok Bot は `kill` や `spawn` をしない）。
