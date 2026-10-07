-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- ============================================================================
-- 基本操作
-- ============================================================================

-- 保存・終了（Windowグループと衝突しないように調整）
-- <leader>w はLazyVimのWindowグループなので使わない
-- 代わりに <leader>fs (file save) を使う
map("n", "<leader>fs", "<cmd>w<cr>", { desc = "💾 Save File" })

-- <leader>q はLazyVimのQuitグループなので、個別マッピングは不要
-- LazyVimのデフォルト <leader>qq を使う

-- バッファ操作
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "← Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "→ Next Buffer" })
map("n", "<leader>bd", "<cmd>bd<cr>", { desc = "🗑️ Delete Buffer" })
map("n", "<leader>bD", "<cmd>%bd|e#<cr>", { desc = "🗑️ Delete Other Buffers" })

-- ウィンドウ移動の改善
map("n", "<C-h>", "<C-w>h", { desc = "← Window Left" })
map("n", "<C-j>", "<C-w>j", { desc = "↓ Window Down" })
map("n", "<C-k>", "<C-w>k", { desc = "↑ Window Up" })
map("n", "<C-l>", "<C-w>l", { desc = "→ Window Right" })

-- ウィンドウリサイズ
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "↑ Increase Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "↓ Decrease Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "← Decrease Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "→ Increase Width" })

-- ============================================================================
-- 編集操作
-- ============================================================================

-- 行移動（ビジュアルモード）
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "↓ Move Line Down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "↑ Move Line Up" })

-- インデント（ビジュアルモードで選択維持）
map("v", "<", "<gv", { desc = "← Indent Left" })
map("v", ">", ">gv", { desc = "→ Indent Right" })

-- 貼り付け時にレジスタを保持
map("v", "p", '"_dP', { desc = "📋 Paste (keep register)" })

-- 行連結時にカーソル位置維持
map("n", "J", "mzJ`z", { desc = "🔗 Join Lines" })

-- 検索時に画面中央に
map("n", "n", "nzzzv", { desc = "→ Next Search" })
map("n", "N", "Nzzzv", { desc = "← Prev Search" })

-- ============================================================================
-- ファイル操作
-- ============================================================================

-- File Explorer（Snacks explorer - LazyVimデフォルト）
map("n", "<leader>e", function()
  require("snacks").explorer()
end, { desc = "📁 Explorer" })

map("n", "<leader>E", function()
  require("snacks").explorer({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "📂 Explorer (Current File Dir)" })

-- ============================================================================
-- Git操作
-- ============================================================================

-- LazyGit
map("n", "<leader>gg", function()
  require("snacks").lazygit()
end, { desc = "🔀 LazyGit" })

-- ============================================================================
-- ターミナル
-- ============================================================================

-- フローティングターミナル
map("n", "<leader>tt", function()
  require("snacks").terminal()
end, { desc = "💻 Terminal (Float)" })

map("n", "<leader>tT", function()
  require("snacks").terminal(nil, { cwd = vim.fn.getcwd() })
end, { desc = "💻 Terminal (cwd)" })

-- ターミナルモードでの移動
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "← Window Left" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "↓ Window Down" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "↑ Window Up" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "→ Window Right" })
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

-- ============================================================================
-- その他
-- ============================================================================

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "🔍 Clear Search" })

-- Better up/down（wrapped linesでの移動）
-- descを削除してWhich-Keyに表示させない（overlapping警告回避）
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Lazy（プラグインマネージャー）
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "🔌 Lazy" })

-- Notifications
map("n", "<leader>un", function()
  require("snacks").notifier.hide()
end, { desc = "🔕 Dismiss All Notifications" })

-- Quit all（LazyVimデフォルトを上書き）
-- map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "🚪 Quit All" })
