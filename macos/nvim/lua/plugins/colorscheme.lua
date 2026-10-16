-- 背景を透過して、Ghostty の色が透けるようにする。色は p10k / Oh My Posh と同じパステル。
-- 補完やピッカーなどの浮き窓は、文字が読めるように背景を残す。
local pastel = {
  rosewater = "#ffc9b0",
  flamingo = "#ff8fb1",
  pink = "#f5a8d6",
  mauve = "#c9b6ff",
  red = "#ff8fb1",
  maroon = "#e8899f",
  peach = "#ffc9b0",
  yellow = "#fff0b3",
  green = "#a8ecd8",
  teal = "#7ed0c4",
  sky = "#a8d8ff",
  sapphire = "#8ec4e6",
  blue = "#9ec8f0",
  lavender = "#b9a3e8",
  text = "#f3e9f8",
  subtext1 = "#e4d4ef",
  subtext0 = "#cbb8dc",
  overlay2 = "#b9a3e8",
  overlay1 = "#9a86b8",
  overlay0 = "#7a6894",
  surface2 = "#6e5690",
  surface1 = "#4a3458",
  surface0 = "#3a2440",
  base = "#221a28",
  mantle = "#1c1522",
  crust = "#161018",
}

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "frappe",
      transparent_background = true,
      dim_inactive = { enabled = false },
      float = { transparent = false },
      color_overrides = { frappe = pastel },
      custom_highlights = function(colors)
        local none = "NONE"
        -- render-markdown の見出しとコードは、リンク先（Diff や ColorColumn）の背景で画像を隠す。
        local clear = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH3Bg",
          "RenderMarkdownH4Bg",
          "RenderMarkdownH5Bg",
          "RenderMarkdownH6Bg",
          "RenderMarkdownCode",
          "RenderMarkdownCodeInline",
          "RenderMarkdownCodeBorder",
          "RenderMarkdownCodeInfo",
        }
        local highlights = {
          NormalFloat = { bg = colors.base },
          FloatBorder = { fg = colors.lavender, bg = colors.base },
          Pmenu = { bg = colors.base },
        }
        for _, name in ipairs(clear) do
          highlights[name] = { bg = none }
        end
        return highlights
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-frappe",
    },
  },
}
