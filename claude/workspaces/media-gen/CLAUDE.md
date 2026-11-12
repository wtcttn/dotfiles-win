# 画像・動画の生成（fal.ai）

このファイルと `.mcp.json` の正本は dotfiles の `claude/workspaces/media-gen/` である。ここで直さず dotfiles を直し、`windows/install-powershell.ps1 claude` で入れ直す。

このフォルダで起動した Claude Code だけが、fal.ai の MCP（`fal`、`https://mcp.fal.ai/mcp-relay`）を使える（このフォルダの `.mcp.json`、project スコープ）。初回は `/mcp` から `fal` を選んでブラウザでログインする。

## 承認が要ること

fal.ai はモデルを動かすたびに課金される。

- 生成は、オーナーが依頼文で枚数か上限額を認めたときだけ行う。モデルを探す、料金を調べるだけなら承認は要らない。
- 動画や高解像度など1回が高いものは、先に1回あたりの料金を見せる。
- 生成した画像を外部に公開・投稿しない。

## 置き場所

- 生成物は `outputs\YYYY-MM-DD\<作業名>\` に保存し、使ったモデル、指示文、参考画像、料金を同じフォルダの `README.md` に残す。
- キャラクターの正典は `C:\Users\kento\workspace\wtcttn\jishou-hensanshitsu\characters\` と `sources\images\`。正典の画像は読むだけで、書き換えない。
