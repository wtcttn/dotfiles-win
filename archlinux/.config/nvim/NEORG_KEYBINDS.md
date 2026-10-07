# Neorg キーバインド

Neorgファイル（`.norg`）編集時のみ有効なキーバインドです。

**LocalLeader** = `\`（バックスラッシュ）

すべてのNeorgキーバインドは `<LocalLeader>n` プレフィックスを使用します。

---

## 📝 基本操作

| キー | 説明 |
|------|------|
| `<LocalLeader>nn` | 📑 目次表示 (Table of Contents) |
| `<LocalLeader>nt` | 👁️ Concealerトグル |

---

## ✅ タスク管理

| キー | 説明 |
|------|------|
| `<LocalLeader>nts` | 🔄 タスク状態サイクル |
| `<LocalLeader>ntd` | ✅ タスク完了 (Done) |
| `<LocalLeader>ntu` | ⬜ タスク未完了 (Undone) |
| `<LocalLeader>ntp` | ⏳ タスク保留 (Pending) |
| `<LocalLeader>ntc` | ❌ タスク中止 (Cancelled) |

---

## 📋 リスト操作

| キー | 説明 |
|------|------|
| `<LocalLeader>nli` | 🔄 リスト反転 (Invert) |
| `<LocalLeader>nlt` | 🔄 リストトグル |

---

## 📊 階層操作

| キー | 説明 | モード |
|------|------|--------|
| `<LocalLeader>n>` | ↑ プロモート（階層を上げる） | Normal |
| `<LocalLeader>n<` | ↓ デモート（階層を下げる） | Normal |
| `<LocalLeader>n>` | ↑ プロモート（範囲） | Visual |
| `<LocalLeader>n<` | ↓ デモート（範囲） | Visual |

---

## 🛠️ その他

| キー | 説明 |
|------|------|
| `<LocalLeader>ncm` | 🔍 コードブロック拡大 |
| `<LocalLeader>nid` | 📅 日付挿入 |

---

## 💡 ヒント

### タスクの使い方

1. `- [ ]` と入力してタスクを作成
2. `<LocalLeader>nts` でタスク状態をサイクル：
   - `[ ]` → `[x]` → `[-]` → `[!]` → ...

### 階層の使い方

1. `*` でヘッディングを作成（`*`, `**`, `***`で階層）
2. 行にカーソルを置いて `<LocalLeader>n>` で階層を上げる
3. `<LocalLeader>n<` で階層を下げる
4. Visual modeで複数行を選択して一括変更も可能

---

## 📚 参考

- [Neorg公式ドキュメント](https://github.com/nvim-neorg/neorg)
- [Neorg Wiki](https://github.com/nvim-neorg/neorg/wiki)

