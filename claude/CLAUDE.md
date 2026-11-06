# Claude Code のユーザー指示

`~/.claude/CLAUDE.md` の正本は dotfiles の `claude/CLAUDE.md` である。Windows は `windows/install-powershell.ps1 claude` が、このファイルを `@` で読み込む1行を `~/.claude/CLAUDE.md` に置く。このリポジトリは公開なので、ここには索引だけを置く。ルールは書き写さず、正本を読む。秘密情報や公開したくない指示は、リポジトリに入れない `~/.claude/CLAUDE.local.md` に書く（無ければ読まれないだけ）。

@~/.claude/CLAUDE.local.md

## 正本

作業の前に、該当する正本を読む。このファイルと正本が食い違ったら正本に従い、このファイルを直す。

| 何を | 正本 |
| --- | --- |
| ノートを書く・読む | ボルト直下の `AGENTS.md` |
| Grok Bot の役割分担 | ボルトの `maps/Grok Botのハーネス設計.md` と、そこからリンクされた地図 |
| Grok Bot からの依頼の受け方、常駐ペインとフォルダの割り当て | dotfiles の `grokbot/claude-code.md` |
| Blender・After Effects、Studio One、画像・動画の生成 | `C:\Users\kento\workspace\cg`、`music`、`media-gen` の `CLAUDE.md`。アプリの MCP はそのフォルダで起動したときだけ使える |
| 共通スキル | dotfiles の `cursor/skills/`（`~/.claude/skills/` にリンクしてある） |
| 開発環境（WSLc、WezTerm、ノートの同期） | dotfiles の `AGENTS.md` |
| 各リポジトリ | そのリポジトリの `AGENTS.md`、`CLAUDE.md`、`README.md` |
| 事象編纂室の設定とことねの運用 | jishou-hensanshitsu の `README.md` と `bot/README.md`。正典は `world/`・`organizations/`・`characters/` |

## パス

Grok Bot はボックスのパスで指示してくる。この PC では次のように読み替える。

| もの | Windows | WSLc コンテナ | Grok Bot のボックス |
| --- | --- | --- | --- |
| ボルト | `C:\Users\kento\notes` | `/mnt/notes` | `/home/box/sync/obsidian-vault`（`~/notes`） |
| dotfiles | `C:\Users\kento\dotfiles` | | ボックスの clone |
| 開発リポジトリ | `C:\Users\kento\workspace\{org}\{repo}` | `/workspace/{org}/{repo}` | `/home/box/repos/{repo}` |
| jishou-hensanshitsu | `C:\Users\kento\workspace\wtcttn\jishou-hensanshitsu` | `/workspace/wtcttn/jishou-hensanshitsu` | `/home/box/repos/jishou-hensanshitsu` |

## 読む前に

リポジトリの正本は、ボックスや Cursor のクラウドエージェントが先に更新していることがある。読む前に `git fetch` し、作業ツリーがきれいで `main` が遅れているときだけ `git pull --ff-only` する。未コミットの変更や別ブランチがあれば触らず、古いかもしれないと断って読む。ボルトは Syncthing で揃うので pull は要らないが、ボックスで書いた内容がこの PC に届くまで、おおよそ1分かかることがある。Grok Bot が直前にボルトへ書かせた内容を読むときは、`grokbot/claude-code.md` の「ボルトの同期の遅れ」のとおり、更新時刻を確かめてから読む。この PC でボルトに書いたときも、Grok Bot から見えるまで同じだけかかる。

## Grok Bot から来た依頼

先頭が `[Grok Bot` で始まる入力は Grok Bot からの依頼である。`grokbot/claude-code.md` を読んでから動く。ボルトには書かず、結果を画面に返す。
