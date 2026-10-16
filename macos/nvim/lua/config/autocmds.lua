-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- LazyVim は SSH_CONNECTION があると clipboard を空にする。OSC 52 へ繋ぐため戻す。
vim.opt.clipboard = "unnamedplus"
