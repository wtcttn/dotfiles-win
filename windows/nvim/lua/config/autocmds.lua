-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- LazyVim は起動の後半で clipboard を空にすることがある。y をクリップボードに残す。
vim.opt.clipboard = "unnamedplus"
