#!/usr/bin/env python3
"""ボルトの tasks/ から boards/ の Kanban を作り直す。

決まりの正本はボルトの AGENTS.md の「タスク」の節。ここを変えたら、そちらも合わせる。

1. boards/オーナー.md を読み、オーナー担当分の列の移動をノートの status に書き戻す。
   リンクの無いカードは tasks/ にノートを作る。
2. tasks/ の type: task を読み、boards/全体.md と boards/オーナー.md を作り直す。

標準ライブラリだけで動く。結果は JSON で標準出力に出す。
終了コード: 0 = 済んだ、2 = 止めた（同期の衝突、同期の途中など。報告を見てオーナーに知らせる）。
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import time
from pathlib import Path

COLUMNS = ["backlog", "next", "doing", "waiting", "done"]
OWNER = "owner"
ALL_DONE_DAYS = 7
OWNER_DONE_DAYS = 30
BAD_CHARS = re.compile(r'[\\/:*?"<>|#^\[\]]')
LINK = re.compile(r"\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]")
CARD = re.compile(r"^\s*- \[[ xX]\] (.*)$")
SETTINGS_START = "%% kanban:settings"
DEFAULT_SETTINGS = (
    "%% kanban:settings\n```\n"
    + json.dumps({"kanban-plugin": "board", "list-collapse": [False] * len(COLUMNS)})
    + "\n```\n%%\n"
)
VAULT_CANDIDATES = [
    "~/notes",
    "/home/box/sync/obsidian-vault",
    "/mnt/notes",
    "C:/Users/kento/notes",
]


# ---------- ノートの読み書き ----------


class Task:
    def __init__(self, path: Path, text: str):
        self.path = path
        self.title = path.stem
        self.text = text
        self.meta = parse_frontmatter(text)

    def get(self, key: str) -> str:
        return self.meta.get(key, "")

    def set(self, key: str, value: str) -> None:
        self.text = set_frontmatter(self.text, key, value)
        self.meta[key] = value


def parse_frontmatter(text: str) -> dict[str, str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    meta: dict[str, str] = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if not m:
            continue
        value = m.group(2).strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        meta[m.group(1)] = value
    return meta


def set_frontmatter(text: str, key: str, value: str) -> str:
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        raise ValueError("フロントマターが無い")
    end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    new = f"{key}: {value}".rstrip()
    for i in range(1, end):
        if re.match(rf"^{re.escape(key)}:", lines[i]):
            lines[i] = new
            return "\n".join(lines)
    lines.insert(end, new)
    return "\n".join(lines)


def load_tasks(tasks_dir: Path) -> dict[str, Task]:
    tasks: dict[str, Task] = {}
    for path in sorted(tasks_dir.glob("*.md")):
        task = Task(path, path.read_text(encoding="utf-8"))
        if task.get("type") == "task":
            tasks[task.title] = task
    return tasks


def safe_title(text: str) -> str:
    title = BAD_CHARS.sub("-", text).strip().strip(".")
    return re.sub(r"\s+", " ", title)[:120] or "無題"


def new_task_text(status: str, today: str, body: str) -> str:
    meta = [
        "type: task",
        f"status: {status}",
        f"assignee: {OWNER}",
        "project:",
        "waiting_for:",
        "due:",
        f"created: {today}",
        f"done: {today}" if status == "done" else "done:",
        "source: grok-bot",
    ]
    return (
        "---\n" + "\n".join(meta) + "\n---\n\n"
        "## やること\n\n"
        f"{body}\n\n"
        "## メモ\n\n"
        f"- {today}: オーナーのボードに書き足されたカードから作った。\n"
    )


# ---------- ボードの読み書き ----------


def parse_board(text: str) -> tuple[list[tuple[str, str]], list[str]]:
    """(列, カードの文) の並びと、知らない列の名前を返す。"""
    cards: list[tuple[str, str]] = []
    unknown: list[str] = []
    column = None
    for line in text.splitlines():
        if line.startswith(SETTINGS_START):
            break
        if line.startswith("## "):
            column = line[3:].strip().lower()
            if column not in COLUMNS:
                unknown.append(line[3:].strip())
            continue
        m = CARD.match(line)
        if m and column:
            cards.append((column, m.group(1).strip()))
    return cards, unknown


def settings_block(text: str | None) -> str:
    if text and SETTINGS_START in text:
        return text[text.index(SETTINGS_START):].rstrip("\n") + "\n"
    return DEFAULT_SETTINGS


def card_line(task: Task, with_assignee: bool) -> str:
    done = task.get("status") == "done"
    parts = [f"[[{task.title}]]"]
    if with_assignee and task.get("assignee"):
        parts.append(task.get("assignee"))
    if task.get("due") and not done:
        parts.append(f"期限 {task.get('due')}")
    line = " · ".join(parts)
    if task.get("status") == "waiting" and task.get("waiting_for"):
        line += f"（待ち: {task.get('waiting_for')}）"
    return f"- [{'x' if done else ' '}] {line}"


def sort_key(task: Task):
    due = task.get("due") or "9999-99-99"
    return (due, task.get("created") or "9999-99-99", task.title)


def render_board(tasks: list[Task], with_assignee: bool, settings: str) -> str:
    out = ["---", "", "kanban-plugin: board", "", "---", ""]
    for col in COLUMNS:
        out.append(f"## {col}")
        out.append("")
        col_tasks = [t for t in tasks if t.get("status") == col]
        if col == "done":
            col_tasks.sort(key=lambda t: t.get("done") or "", reverse=True)
        else:
            col_tasks.sort(key=sort_key)
        out.extend(card_line(t, with_assignee) for t in col_tasks)
        out.extend(["", ""])
    out.extend(["", ""])
    return "\n".join(out) + settings


def done_within(task: Task, today: dt.date, days: int) -> bool:
    try:
        done = dt.date.fromisoformat(task.get("done"))
    except ValueError:
        return True  # 日付の無い done は、日付が入るまで残す
    return (today - done).days <= days


# ---------- 本体 ----------


def find_vault(arg: str | None) -> Path:
    for cand in [arg, os.environ.get("VAULT_DIR"), *VAULT_CANDIDATES]:
        if cand and (Path(cand).expanduser() / "AGENTS.md").exists():
            return Path(cand).expanduser()
    raise SystemExit("ボルトが見つからない。--vault で渡す")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--vault")
    ap.add_argument("--dry-run", action="store_true", help="書かずに、何をするかだけ出す")
    ap.add_argument("--today", help="YYYY-MM-DD（試験用）")
    ap.add_argument("--settle-seconds", type=int, default=60,
                    help="オーナーのボードがこの秒数以内に変わっていたら、同期の途中とみなして止める")
    args = ap.parse_args()

    vault = find_vault(args.vault)
    tasks_dir, boards_dir = vault / "tasks", vault / "boards"
    owner_board, all_board = boards_dir / "オーナー.md", boards_dir / "全体.md"
    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    today_s = today.isoformat()
    report: dict = {"vault": str(vault), "dry_run": args.dry_run, "status_updates": [],
                    "created": [], "warnings": [], "boards_written": [], "stopped": None}

    def stop(reason: str) -> int:
        report["stopped"] = reason
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 2

    conflicts = [str(p.relative_to(vault)) for d in (tasks_dir, boards_dir) if d.exists()
                 for p in d.glob("*sync-conflict*")]
    if conflicts:
        report["warnings"].append({"sync_conflicts": conflicts})
        return stop("同期の衝突ファイルがある。触らずにオーナーに知らせる")
    if not tasks_dir.is_dir():
        return stop("tasks/ が無い")
    if owner_board.exists() and time.time() - owner_board.stat().st_mtime < args.settle_seconds:
        return stop("オーナーのボードが直前に変わった。同期の途中かもしれないので次の回に回す")

    tasks = load_tasks(tasks_dir)
    changed: dict[Path, str] = {}

    # 1. オーナーのボードを読む
    owner_text = owner_board.read_text(encoding="utf-8") if owner_board.exists() else None
    if owner_text is not None:
        cards, unknown = parse_board(owner_text)
        if unknown:
            report["warnings"].append({"unknown_columns": unknown,
                                       "note": "この列のカードは読まなかった"})
        seen: set[str] = set()
        for column, text in cards:
            m = LINK.search(text)
            if m:
                title = m.group(1).strip()
                task = tasks.get(title)
                if task is None:
                    report["warnings"].append({"missing_note": title})
                    continue
                if title in seen:
                    report["warnings"].append({"duplicate_card": title})
                    continue
                seen.add(title)
                if task.get("assignee") != OWNER:
                    report["warnings"].append({"not_owner_task_on_owner_board": title,
                                               "assignee": task.get("assignee")})
                    continue
                old = task.get("status")
                if old == column:
                    continue
                task.set("status", column)
                if column == "done" and not task.get("done"):
                    task.set("done", today_s)
                if old == "done" and column != "done":
                    task.set("done", "")
                changed[task.path] = task.text
                report["status_updates"].append({"task": title, "from": old, "to": column})
            else:
                body = re.sub(r"\s+@\{[^}]*\}", "", text).strip()  # Kanban の日付の印を外す
                if not body:
                    continue
                title = safe_title(body)
                path = tasks_dir / f"{title}.md"
                if path.exists() or title in tasks:
                    title = f"{title} {today_s}"
                    path = tasks_dir / f"{title}.md"
                if path.exists():
                    report["warnings"].append({"cannot_create": title, "note": "同名が既にある"})
                    continue
                text_new = new_task_text(column, today_s, body)
                task = Task(path, text_new)
                tasks[title] = task
                changed[path] = text_new
                report["created"].append({"task": title, "status": column})

    # 2. ボードを作り直す
    all_tasks = [t for t in tasks.values()
                 if t.get("status") != "done" or done_within(t, today, ALL_DONE_DAYS)]
    owner_tasks = [t for t in tasks.values() if t.get("assignee") == OWNER
                   and (t.get("status") != "done" or done_within(t, today, OWNER_DONE_DAYS))]
    bad = [t.title for t in tasks.values() if t.get("status") not in COLUMNS]
    if bad:
        report["warnings"].append({"unknown_status": bad, "note": "どの列にも載せていない"})

    all_old = all_board.read_text(encoding="utf-8") if all_board.exists() else None
    for path, old, new in [
        (all_board, all_old, render_board(all_tasks, True, settings_block(all_old))),
        (owner_board, owner_text, render_board(owner_tasks, False, settings_block(owner_text))),
    ]:
        if new != old:
            changed[path] = new
            report["boards_written"].append(str(path.relative_to(vault)))

    if not args.dry_run:
        boards_dir.mkdir(exist_ok=True)
        for path, text in changed.items():
            path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
