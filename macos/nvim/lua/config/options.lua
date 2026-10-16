-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.g.lazyvim_picker = "snacks"
vim.g.lazyvim_explorer = "snacks"

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
-- Mac ではシステムのクリップボードを使う。コンテナ側の OSC 52 はここでは使わない。
vim.opt.clipboard = "unnamedplus"
vim.opt.shell = "zsh"
