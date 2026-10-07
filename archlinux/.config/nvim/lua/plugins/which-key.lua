return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      icons = {
        separator = "→",
        group = "󰉋 ",
      },
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
      delay = 200,
      
      -- プラグイン設定
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
        presets = {
          -- presetsを無効化してoverlapping警告を減らす
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
          z = false,
          g = false,
        },
      },
      
      -- グループ定義は空（LazyVimデフォルトのみ）
      spec = {},
    },
  },
}

