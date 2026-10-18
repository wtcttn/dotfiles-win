-- 画面下の zsh。ノーマルモードでは <leader>tt と Ctrl-\。
-- 端末の中では Ctrl-\ で隠す。Esc を二度でノーマルモードに戻る。

local function toggle_terminal()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>tt", toggle_terminal, desc = "ターミナル", mode = "n" },
      { "<C-\\>", toggle_terminal, desc = "ターミナル", mode = "n" },
    },
    opts = {
      terminal = {
        win = {
          -- フォーカスが外れると SnacksNormalNC（浮き窓の不透明な色）が壁紙を隠す。
          wo = {
            winhighlight = "Normal:Normal,NormalNC:Normal,WinBar:SnacksWinBar,WinBarNC:SnacksWinBarNC,WinSeparator:SnacksWinSeparator",
          },
          keys = {
            hide_backslash = { "<C-\\>", "hide", desc = "ターミナルを隠す", mode = "t" },
          },
        },
      },
    },
  },
}
