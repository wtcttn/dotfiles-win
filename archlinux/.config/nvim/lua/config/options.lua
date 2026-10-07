-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.termguicolors = true -- 端末のカラースキームを有効にする
vim.opt.winblend = 0 -- 透明度は使わない（シンプルに）
vim.opt.pumblend = 0 -- 透明度は使わない（シンプルに）

-- ============================================================================
-- プロバイダー設定
-- ============================================================================

-- Clipboard設定（wl-clipboardを使用）
vim.g.clipboard = {
  name = "wl-clipboard",
  copy = {
    ["+"] = "wl-copy",
    ["*"] = "wl-copy",
  },
  paste = {
    ["+"] = "wl-paste --no-newline",
    ["*"] = "wl-paste --no-newline",
  },
  cache_enabled = 1,
}

-- 不要なプロバイダーを無効化（警告抑制）
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
