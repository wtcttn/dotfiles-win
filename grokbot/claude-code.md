# Grok Bot から Claude Code への依頼

Grok Bot と、オーナーの PC で動く Claude Code のあいだの取り決めの正本である。両方がこれを読む。Grok Bot が送る手順はスキル `hub-bridge`、hub がいないときに用意する手順はスキル `hub-keeper`、Claude Code の入口は `claude/CLAUDE.md`（`~/.claude/CLAUDE.md`）にある。

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

参謀から Claude Code への依頼は、ブリッジ `hub-bridge`（dotfiles の `claude/bridge/`）で `hub` に送る。窓口は Grok Bot 側が参謀、Claude Code 側が `hub` の1組だけで、各ペインへの振り分けは hub が `SendMessage` で行う。ほかの Bot が Claude Code に頼むときは、参謀を通す。

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

- 依頼元: `参謀`、`ことね運用`、`ノート管理` など。
- 正本: その作業のルールが書いてあるファイル。ボックスのパスでよい（Claude Code が読み替える）。無ければ省く。
- 書いてよい場所: 省いたときは `なし`（読むだけ、画面に返すだけ）とみなす。
- ボルト更新: 直前にボックス側（ノート管理など）がボルトに書き、Claude Code にそれを読ませるときだけ付ける。`ボルト更新: <ボルト内のパス> <更新時刻>`。時刻は `2026-11-05T23:40+09:00` の形。複数あるときは `,` で区切る。

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

### 動画の制作の順番（仮組みを先に見る）

- 本番の描画（Blender の描画、生成、本番の書き出し）の前に、仮組みを作る。仮組みは、仮の絵（静止画、ラフ、文字だけのカードでもよい）・仮の声・字幕を、台本の尺で並べた通しの動画である。
- オーナーが仮組みを見て OK を出すまで、本番を描かない。OK は、制作フォルダの `README.md` に「仮組みの承認: <日付>、台本 v<版>、<仮組みのファイル>」と書いて残す。
- OK のあとに台本を直すときは、先に台本の版を上げる（`v2` → `v2.1`。上書きしない）。直しは、カット ID と台詞 ID ごとに担当のペインへ振り分け、描き直すのは変わったカットだけにする。
- 大きな直しで尺や並びが変わったときは、仮組みを作り直して、もう一度 OK をもらう。
- 2026-11-09 の出口クイズでは、仮組みを見る前に本番 v1（描画におよそ 88 分）を描き、v2.1 の直しで全部を描き直した。この決まりは、そのくり返しを防ぐためのものである。

## ボルトの同期の遅れ

ボルトは Syncthing で揃うので、ボックスで書いた内容がこの PC に届くまで、おおよそ1分かかることがある。

- Grok Bot は、ボルトに書いてもらった直後に、その内容を前提とした依頼を送るときは、印に `ボルト更新:` を付ける。急がないときは、書いてから1分ほど置いて送る。
- Claude Code は、`ボルト更新:` のファイルの更新時刻がその時刻より前なら（Syncthing は元の更新時刻を運ぶ）、まだ届いていない。30秒ほどおきに見直し、約3分たっても届かなければ `エラー: ボルトが未同期（<パス>）` で締める。古い内容のまま進めない。
- 同じ名前の `*.sync-conflict*` があれば、どちらが正しいか決めずに `エラー:` で知らせる。消したりマージしたりしない。
- 逆向きも同じである。オーナーに頼まれて Claude Code がボルトに書いた直後は、Grok Bot から見えるまで1分ほどかかる。画面の結果に、書いたパスと時刻を添える。

例:

```text
[Grok Bot / 依頼元: 参謀 / 正本: /home/box/repos/my-mv-conte-tools/AGENT.md / 書いてよい場所: なし] After Effects で開いているコンポの名前と長さを教えてください
```

## Claude Code がすること

1. 印に `ボルト更新:` があれば、上の「ボルトの同期の遅れ」のとおり届いたかを確かめる。
2. 印の正本と、`claude/CLAUDE.md` の正本のうち関係するものを読む。パスはこの PC のものに読み替える。
3. 依頼の範囲だけを行う。書いてよい場所の外は変更しない。
4. hub は、ブリッジの `reply` で結果を返す（`kind: result`、`status: ok` か `error`、`reply_to` に依頼の id）。参謀はこれを見て終わったと判断する。hub が各ペインに振り分けたときは、ペインの報告をまとめてから返す。

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
