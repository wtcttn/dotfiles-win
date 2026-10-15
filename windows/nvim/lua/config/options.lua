-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.g.lazyvim_picker = "snacks"
vim.g.lazyvim_explorer = "snacks"

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.confirm = true
vim.opt.undofile = true

-- y や p を Windows のクリップボードに繋ぐ。
vim.opt.clipboard = "unnamedplus"
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
