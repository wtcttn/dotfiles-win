-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "norg", "neorg" },
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_augroup("BashScripts", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = "BashScripts",
  pattern = { "*.sh" },
  callback = function(args)
    -- 1行目を読み込む
    local line = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)[1]
    -- 1行目が #! で始まっていれば実行権限を付与
    if line and line:match("^#!") then
      vim.fn.system("chmod +x " .. vim.fn.expand("<afile>"))
    end
  end,
})
