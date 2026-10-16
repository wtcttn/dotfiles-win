-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- LazyVim は SSH_CONNECTION があると clipboard を空にする。OSC 52 へ繋ぐため戻す。
vim.opt.clipboard = "unnamedplus"

-- LazyVim は markdown で英語のスペルチェックを付ける。日本語のノートは全部ミスになるので切る。
-- このファイルは LazyVim 本体の autocmd より後に読まれるので、こちらが優先される。
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_nospell", { clear = true }),
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})
