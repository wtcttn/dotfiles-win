-- Windows 用の Neovim。開発リポジトリは WSLc コンテナの nvim で開く。
-- 言語サーバーは入れない。%LOCALAPPDATA%\nvim-data に積まれるため。
-- コンテナ用の wslc-dev/home/.config/nvim と、Arch 用の archlinux/.config/nvim とは共有しない。

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false
vim.opt.scrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.confirm = true
vim.opt.undofile = true
vim.opt.updatetime = 300
vim.opt.fileencoding = "utf-8"

-- クリップボードは未設定のままにする。"+ と "* だけが Windows 標準のプロバイダを使う。
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "lazy.nvim の取得に失敗しました\n" .. out, "ErrorMsg" } }, true, {})
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "default" } },
  checker = { enabled = false },
  change_detection = { enabled = false },
})
