-- Markdown の表示と編集。言語サーバーは入れない。
-- Neovim 0.12 に同梱の markdown / markdown_inline パーサーを使う。
-- コンテナ側の wslc-dev/home/.config/nvim/lua/plugins/markdown.lua と同じ構成だが、ファイルは共有しない。

return {
  {
    "nvim-mini/mini.icons",
    opts = {},
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-mini/mini.icons" },
    ---@module "render-markdown"
    ---@type render.md.UserConfig
    opts = {
      latex = { enabled = false },
    },
  },
  {
    "tadmccorkle/markdown.nvim",
    ft = "markdown",
    opts = {},
  },
}
