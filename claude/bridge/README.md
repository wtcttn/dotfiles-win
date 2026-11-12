# hub-bridge

Grok Bot（参謀）と、SUGIMOTO-PC の Claude Code `hub` をつなぐブリッジ。`wezterm cli send-text` で画面に打ち込む代わりに、メッセージでやりとりする。決まりは `grokbot/claude-code.md` の「ブリッジ」、hub 側の扱いは `claude/workspaces/hub/CLAUDE.md`。

```
参謀 ──MCP（Tailscale、PC の 8788 番 /mcp）──▶ hub-bridge ──Channels──▶ hub ──SendMessage──▶ 各ペイン
参謀 ◀──webhook の定期タスク（HTTPS）／get_replies── hub-bridge ◀──reply── hub
```

## 動き

- hub の Claude Code が `.mcp.json` の `hub-bridge` として stdio で起動する。hub を閉じるとブリッジも止まる。
- hub 側には Channels のチャネル（`claude/channel`）として見え、ツール `reply`、`bridge_status` を持つ。研究プレビューの間は `--dangerously-load-development-channels server:hub-bridge` が要る（`cc hub` が `claude/workspaces/hub/channels` を読んで付ける）。
- tailnet 側は、PC の Tailscale のアドレス（`tailscale ip -4`）の 8788 番、パス `/mcp` で、Streamable HTTP（状態なし）の MCP サーバーとして待つ。Grok Bot には MCP サーバー `hub-bridge` として登録してある。ツールは `ping`、`send_to_hub`、`get_replies`。
- `send_to_hub` で届いたものは `id` で重複を除き、`inbox.jsonl` に記録して hub に押し込む。
- hub の `reply` は `outbox.jsonl` に記録し、設定があれば参謀の webhook に POST する。参謀は `get_replies(after)` でも取りに来られる。
- 記録は `%USERPROFILE%\workspace\hub\bridge\`（`HUB_BRIDGE_DIR` で変えられる）。秘密は書かない。

## 守り

- Tailscale のポリシー（`tailscale/policy.hujson`）で、Grok Bot の利用者からは PC の 8788 番にしか届かない。箱は Bot 用アカウントの tailnet にいて、SUGIMOTO-PC だけを共有されている。
- `HUB_BRIDGE_TOKEN` があれば、`Authorization: Bearer <鍵>` の無い要求は 401 で断る。Grok Bot の MCP の登録には、オーナーがこのヘッダーを足す（値は参謀を通さない）。
- 本文は 32 KB まで。大きいファイルは制作フォルダに置き、パスだけを送る。

## 環境変数

| 名前 | 中身 | 出どころ |
| --- | --- | --- |
| `HUB_BRIDGE_TOKEN` | 参謀 → ブリッジの鍵 | Bitwarden `hub-bridge-token`（`claude/workspaces/hub/secrets.bw`） |
| `GROKBOT_WEBHOOK_URL` | 参謀の webhook の定期タスクの URL | Bitwarden `grokbot-webhook-url` |
| `GROKBOT_WEBHOOK_KEY` | webhook の鍵 | Bitwarden `grokbot-webhook-key` |
| `GROKBOT_WEBHOOK_HEADER` | 鍵を載せるヘッダー名。空なら `Authorization: Bearer` | 必要になったら `.mcp.json` か環境変数で |
| `HUB_BRIDGE_PORT` | 待ち受けの番号（既定 8788） | |
| `HUB_BRIDGE_DIR` | 記録の置き場 | |

## 入れ方

`windows/install-powershell.ps1 claude` が、hub の `.mcp.json` をコピーし、このフォルダで `npm ci` を実行する。直したら hub を `cc hub` で起動し直す。Windows ファイアウォールには、Tailscale のアドレス帯（`100.64.0.0/10`）からの TCP 8788 だけを通す規則 `hub-bridge-tailscale-8788` がある（オーナーが管理者で入れた）。
