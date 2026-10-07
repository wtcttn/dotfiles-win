return {
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        dim_inactive = {
          enabled = false,
        },
        integrations = {
          -- すべての統合を無効化（背景色を設定させない）
        },
        custom_highlights = function()
          return {
            -- すべての背景を透明にする
            Normal = { bg = "NONE" },
            NormalNC = { bg = "NONE" },
            NormalFloat = { bg = "NONE" },
            FloatBorder = { bg = "NONE" },
            FloatTitle = { bg = "NONE" },

            -- エディタ関連
            SignColumn = { bg = "NONE" },
            FoldColumn = { bg = "NONE" },
            LineNr = { bg = "NONE" },
            CursorLineNr = { bg = "NONE" },
            CursorLine = { bg = "NONE" },

            -- Snacks Explorer（ファイルエクスプローラー）
            SnacksExplorerNormal = { bg = "NONE" },
            SnacksExplorerNormalNC = { bg = "NONE" },

            -- Telescope
            TelescopeNormal = { bg = "NONE" },
            TelescopeBorder = { bg = "NONE" },

            -- Popup
            Pmenu = { bg = "NONE" },
            PmenuSbar = { bg = "NONE" },

            -- Which-Key
            WhichKeyFloat = { bg = "NONE" },
            WhichKeyBorder = { bg = "NONE" },

            -- Lazy
            LazyNormal = { bg = "NONE" },

            -- Mason
            MasonNormal = { bg = "NONE" },

            -- Notify
            NotifyBackground = { bg = "NONE" },
          }
        end,
      })

      vim.cmd.colorscheme("catppuccin-frappe")
    end,
  },
}
