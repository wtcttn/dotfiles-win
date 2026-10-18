-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.g.lazyvim_picker = "snacks"
vim.g.lazyvim_explorer = "snacks"

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.clipboard = "unnamedplus"
vim.opt.shell = "zsh"

-- 実験。graf でボルトのリンクを見る。日次と原本は除外する。
-- バイナリと note-graph-open、設定は install-graf.sh がホームへ置く。
-- Enter は note-graph-open 経由で、今の Neovim の新しいタブに開く。
-- jobstart の term は未変更の今のバッファを端末に作り替える。
-- ダッシュボードのまま分割すると、絵の extmark が両画面に残る。
vim.api.nvim_create_user_command("NoteGraph", function()
  if vim.v.servername == nil or vim.v.servername == "" then
    vim.fn.serverstart()
  end
  local notes = "/mnt/notes"
  local graf = vim.fn.expand("~/.local/bin/graf")
  local opener = vim.fn.expand("~/.local/bin/note-graph-open")
  local config = vim.fn.expand("~/.config/graf/config.toml")
  if vim.fn.executable(graf) == 0 or vim.fn.executable(opener) == 0 or vim.fn.filereadable(config) == 0 then
    vim.notify("graf が未導入です。install-graf.sh を実行してください", vim.log.levels.ERROR)
    return
  end
  vim.cmd.enew()
  local win = vim.api.nvim_get_current_win()
  vim.fn.jobstart({
    graf,
    "--config",
    config,
    "--dir",
    notes,
    "--theme",
    "catppuccin_mocha",
    "--node-color-mode",
    "folder",
    "--label-mode",
    "neighbors",
    "--background",
    "solid",
    "--exclude",
    "daily/*",
    "--exclude",
    "digests/*",
    "--exclude",
    "kotone/*",
    "--exclude",
    "templates/*",
    "--exclude",
    "attachments/*",
    "--exclude",
    "*sync-conflict*",
    "--editor",
    opener,
  }, {
    term = true,
    cwd = notes,
    env = { NVIM = vim.v.servername },
  })
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].statuscolumn = ""
  vim.wo[win].foldcolumn = "0"
  local buf = vim.api.nvim_get_current_buf()
  -- ノートを開いて戻るとノーマルモードになる。graf のキーは端末モードでしか届かない。
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    buffer = buf,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() ~= buf or vim.fn.mode() == "t" then
          return
        end
        vim.cmd.startinsert()
      end)
    end,
  })
  vim.cmd.startinsert()
end, { desc = "ボルトのリンクを graf で開く（実験）" })

local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if ok then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
end
