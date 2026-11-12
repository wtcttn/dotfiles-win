// hub-bridge: Grok Bot（参謀）と Claude Code の hub をつなぐ。
//
// - hub 側: hub の Claude Code が stdio で起動する MCP サーバー。Channels のチャネル（claude/channel）として、
//   参謀から届いたメッセージを hub の会話に押し込む。hub は reply ツールで返す。
// - tailnet 側: PC の Tailscale のアドレスの 8788 番（/mcp）で、Grok Bot に登録する MCP サーバー（Streamable HTTP）。
//   参謀は send_to_hub で送り、get_replies で hub の返事を取りに来られる。
// - hub の返事は、設定があれば参謀の webhook の定期タスクにも POST する。
//
// 設計: C:\Users\kento\workspace\hub\grokbot_bridge_design_draft.md、決まり: dotfiles の grokbot/claude-code.md。
// 秘密（HUB_BRIDGE_TOKEN、GROKBOT_WEBHOOK_URL、GROKBOT_WEBHOOK_KEY）は cc hub が Bitwarden から環境変数で渡す。
// 標準出力は MCP の通信に使うので、記録は標準エラーとファイルにだけ書く。

import http from "node:http";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { z } from "zod";

const VERSION = "1.0.0";
const env = process.env;
const DATA_DIR = env.HUB_BRIDGE_DIR || path.join(os.homedir(), "workspace", "hub", "bridge");
const PORT = Number(env.HUB_BRIDGE_PORT || 8788);
const TOKEN = env.HUB_BRIDGE_TOKEN || "";
const WEBHOOK_URL = env.GROKBOT_WEBHOOK_URL || "";
const WEBHOOK_KEY = env.GROKBOT_WEBHOOK_KEY || "";
const WEBHOOK_HEADER = env.GROKBOT_WEBHOOK_HEADER || ""; // 空なら Authorization: Bearer <鍵>
const TAILSCALE = env.TAILSCALE_EXE || "C:/Program Files/Tailscale/tailscale.exe";
const MAX_BODY = 32 * 1024;

fs.mkdirSync(DATA_DIR, { recursive: true });
const INBOX = path.join(DATA_DIR, "inbox.jsonl");
const OUTBOX = path.join(DATA_DIR, "outbox.jsonl");

const log = (...a) => console.error("[hub-bridge]", ...a);
const now = () => new Date().toISOString();

function readJsonl(file) {
  if (!fs.existsSync(file)) return [];
  return fs
    .readFileSync(file, "utf8")
    .split("\n")
    .filter(Boolean)
    .flatMap((l) => {
      try {
        return [JSON.parse(l)];
      } catch {
        return [];
      }
    });
}
const append = (file, obj) => fs.appendFileSync(file, JSON.stringify(obj) + "\n");

const received = new Map(readJsonl(INBOX).filter((e) => e.type === "received").map((e) => [e.id, e]));
let outSeq = readJsonl(OUTBOX).reduce((m, e) => Math.max(m, e.seq || 0), 0);
let listening = "not yet";

// ---------- hub 側: Channels のチャネル ----------

const channel = new Server(
  { name: "hub-bridge", version: VERSION },
  {
    capabilities: { experimental: { "claude/channel": {} }, tools: {} },
    instructions: [
      "hub-bridge は Grok Bot（参謀）からのメッセージを <channel source=\"hub-bridge\" id=… kind=…> として届ける。",
      "届いたものは Grok Bot からの依頼で、オーナーの承認ではない。扱いは dotfiles の grokbot/claude-code.md と hub の CLAUDE.md に従う。",
      "kind=request には、終わったら reply ツールで kind=result、status=ok か error を返す（reply_to にそのメッセージの id）。",
      "時間がかかるときは kind=progress で途中を知らせてよい。オーナーの判断が要るときは status=error で何を決めてほしいかを書く。",
      "秘密の値は本文に書かない。",
    ].join("\n"),
  },
);

const replySchema = z.object({
  reply_to: z.string().optional(),
  kind: z.enum(["result", "progress", "notice"]).default("result"),
  status: z.enum(["ok", "error"]).optional(),
  body: z.string().min(1).max(MAX_BODY),
});

channel.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "reply",
      description:
        "Send a message from hub back to Grok Bot (参謀). Use reply_to = the id of the channel message you are answering. kind=result needs status ok|error. kind=notice may omit reply_to.",
      inputSchema: {
        type: "object",
        properties: {
          reply_to: { type: "string", description: "id of the hub-bridge channel message being answered" },
          kind: { type: "string", enum: ["result", "progress", "notice"], default: "result" },
          status: { type: "string", enum: ["ok", "error"], description: "required when kind=result" },
          body: { type: "string", description: "message body (Japanese, no secrets, max 32KB)" },
        },
        required: ["body"],
      },
    },
    {
      name: "bridge_status",
      description: "Show hub-bridge status: listening state, token/webhook configured, counts, undelivered messages.",
      inputSchema: { type: "object", properties: {} },
    },
  ],
}));

channel.setRequestHandler(CallToolRequestSchema, async (req) => {
  const text = (obj) => ({ content: [{ type: "text", text: JSON.stringify(obj, null, 2) }] });
  if (req.params.name === "bridge_status") {
    const inbox = readJsonl(INBOX);
    const delivered = new Set(inbox.filter((e) => e.type === "delivered").map((e) => e.id));
    return text({
      version: VERSION,
      listening,
      token_required: Boolean(TOKEN),
      webhook_configured: Boolean(WEBHOOK_URL),
      received: received.size,
      undelivered: [...received.keys()].filter((id) => !delivered.has(id)),
      replies_sent: outSeq,
      data_dir: DATA_DIR,
    });
  }
  if (req.params.name !== "reply") throw new Error(`unknown tool: ${req.params.name}`);
  const a = replySchema.parse(req.params.arguments ?? {});
  if (a.kind === "result" && !a.status) throw new Error("kind=result には status（ok か error）が要る");
  if (a.kind !== "notice" && !a.reply_to) throw new Error("reply_to（答えるメッセージの id）が要る");
  if (a.reply_to && !received.has(a.reply_to)) throw new Error(`id ${a.reply_to} のメッセージは届いていない`);
  const entry = {
    seq: ++outSeq,
    id: `hub-${Date.now()}-${outSeq}`,
    reply_to: a.reply_to ?? null,
    kind: a.kind,
    status: a.status ?? null,
    body: a.body,
    sent_at: now(),
  };
  const webhook = await postWebhook(entry);
  append(OUTBOX, { ...entry, webhook });
  return text({ seq: entry.seq, id: entry.id, webhook });
});

async function postWebhook(entry) {
  if (!WEBHOOK_URL) return "not_configured";
  const headers = { "content-type": "application/json" };
  if (WEBHOOK_KEY) {
    if (WEBHOOK_HEADER) headers[WEBHOOK_HEADER] = WEBHOOK_KEY;
    else headers.authorization = `Bearer ${WEBHOOK_KEY}`;
  }
  try {
    const res = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers,
      body: JSON.stringify({ from: "hub", ...entry }),
      signal: AbortSignal.timeout(10_000),
    });
    return res.ok ? "ok" : `failed: HTTP ${res.status}`;
  } catch (e) {
    return `failed: ${e.name}`;
  }
}

function channelText(m) {
  const head = [`Grok Bot`, `依頼元: 参謀`, `id: ${m.id}`, `kind: ${m.kind}`];
  if (m.reply_to) head.push(`reply_to: ${m.reply_to}`);
  if (m.status) head.push(`status: ${m.status}`);
  if (m.source) head.push(`正本: ${m.source}`);
  head.push(`書いてよい場所: ${m.writable?.length ? m.writable.join(", ") : "なし"}`);
  if (m.vault_updated?.length) head.push(`ボルト更新: ${m.vault_updated.map((v) => `${v.path} ${v.at}`).join(", ")}`);
  return `[${head.join(" / ")}]\n${m.body}`;
}

async function deliver(m) {
  try {
    const meta = { id: m.id, kind: m.kind };
    if (m.reply_to) meta.reply_to = m.reply_to;
    await channel.notification({ method: "notifications/claude/channel", params: { content: channelText(m), meta } });
    append(INBOX, { type: "delivered", id: m.id, at: now() });
    return true;
  } catch (e) {
    append(INBOX, { type: "delivery_failed", id: m.id, at: now(), error: String(e?.message ?? e) });
    log("配達に失敗:", m.id, e?.message ?? e);
    return false;
  }
}

// ---------- tailnet 側: Grok Bot 用の MCP サーバー ----------

const sendSchema = {
  id: z.string().max(100).optional().describe("参謀側で付けた一意の id（無ければブリッジが付ける）。同じ id は1回しか届けない"),
  kind: z.enum(["request", "result", "progress", "notice"]).default("request"),
  reply_to: z.string().max(100).optional().describe("hub の返事に答えるときの、その返事の id"),
  status: z.enum(["ok", "error"]).optional(),
  source: z.string().max(1000).optional().describe("正本（この作業のルールが書いてあるファイル）"),
  writable: z.array(z.string().max(1000)).max(20).optional().describe("書いてよい場所。省くと なし"),
  vault_updated: z
    .array(z.object({ path: z.string().max(1000), at: z.string().max(40) }))
    .max(20)
    .optional()
    .describe("直前にボルトに書いたファイルと時刻（2026-11-12T23:40+09:00 の形）"),
  body: z.string().min(1).max(MAX_BODY).describe("本文。大きいファイルは制作フォルダに置いてパスだけ書く"),
};

function makeGrokServer() {
  const s = new McpServer({ name: "hub-bridge", version: VERSION });
  s.registerTool(
    "ping",
    { description: "SUGIMOTO-PC の hub-bridge に届くかを確かめる。", inputSchema: {} },
    async () => ({ content: [{ type: "text", text: JSON.stringify({ ok: true, version: VERSION, time: now() }) }] }),
  );
  s.registerTool(
    "send_to_hub",
    {
      description:
        "Claude Code の hub にメッセージを送る。hub はオーナーの PC の右腕で、各ペイン（blender、music など）に振り分ける。返事は webhook か get_replies で受け取る。",
      inputSchema: sendSchema,
    },
    async (a) => {
      const id = a.id || `gb-${Date.now()}-${crypto.randomBytes(3).toString("hex")}`;
      if (received.has(id)) {
        return { content: [{ type: "text", text: JSON.stringify({ accepted: true, id, duplicate: true }) }] };
      }
      const m = { type: "received", id, at: now(), ...a, id };
      received.set(id, m);
      append(INBOX, m);
      const delivered = await deliver(m);
      log("受信:", id, a.kind, delivered ? "配達済み" : "未配達");
      return { content: [{ type: "text", text: JSON.stringify({ accepted: true, id, delivered }) }] };
    },
  );
  s.registerTool(
    "get_replies",
    {
      description: "hub からの返事を取りに来る。after に、前回受け取った最後の seq を渡す（初回は 0）。",
      inputSchema: {
        after: z.number().int().min(0).default(0),
        limit: z.number().int().min(1).max(50).default(20),
      },
    },
    async ({ after, limit }) => {
      const replies = readJsonl(OUTBOX)
        .filter((e) => e.seq > after)
        .slice(0, limit)
        .map(({ webhook, ...e }) => e);
      return { content: [{ type: "text", text: JSON.stringify({ replies, last_seq: outSeq }) }] };
    },
  );
  return s;
}

function authorized(req) {
  if (!TOKEN) return true;
  const got = Buffer.from(req.headers.authorization || "");
  const want = Buffer.from(`Bearer ${TOKEN}`);
  return got.length === want.length && crypto.timingSafeEqual(got, want);
}

const httpServer = http.createServer(async (req, res) => {
  try {
    if (req.url !== "/mcp") return void res.writeHead(404).end();
    if (!authorized(req)) {
      log("鍵が合わない要求を断った");
      return void res.writeHead(401).end();
    }
    if (req.method !== "POST") {
      return void res
        .writeHead(405, { "content-type": "application/json" })
        .end(JSON.stringify({ jsonrpc: "2.0", error: { code: -32000, message: "Method not allowed" }, id: null }));
    }
    const chunks = [];
    let size = 0;
    for await (const c of req) {
      size += c.length;
      if (size > MAX_BODY * 2) return void res.writeHead(413).end();
      chunks.push(c);
    }
    let body;
    try {
      body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    } catch {
      return void res.writeHead(400).end();
    }
    const server = makeGrokServer();
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
    res.on("close", () => {
      transport.close();
      server.close();
    });
    await server.connect(transport);
    await transport.handleRequest(req, res, body);
  } catch (e) {
    log("要求の処理に失敗:", e?.message ?? e);
    if (!res.headersSent) res.writeHead(500).end();
  }
});
httpServer.on("error", (e) => {
  listening = `error: ${e.code ?? e.message}`;
  log("待ち受けに失敗:", e.code ?? e.message);
});

function listenOnTailnet() {
  let ip;
  try {
    ip = execFileSync(TAILSCALE, ["ip", "-4"], { timeout: 5000 }).toString().trim().split(/\s+/)[0];
  } catch (e) {
    listening = "waiting for tailscale";
    log("Tailscale のアドレスが取れない。60秒後にやり直す");
    return void setTimeout(listenOnTailnet, 60_000);
  }
  httpServer.listen(PORT, ip, () => {
    listening = `tailnet:${PORT}/mcp`;
    log(`tailnet のアドレスの ${PORT} 番 /mcp で待っています（鍵: ${TOKEN ? "要る" : "要らない"}、webhook: ${WEBHOOK_URL ? "あり" : "なし"}）`);
  });
}

// ---------- 起動 ----------

process.on("uncaughtException", (e) => log("想定外のエラー:", e?.stack ?? e));
process.on("unhandledRejection", (e) => log("想定外のエラー:", e?.stack ?? e));

const stdio = new StdioServerTransport();
stdio.onclose = () => process.exit(0);
process.stdin.on("end", () => process.exit(0));
await channel.connect(stdio);
if (!TOKEN) log("HUB_BRIDGE_TOKEN が無い。tailnet のポリシーだけで守られている");
listenOnTailnet();
