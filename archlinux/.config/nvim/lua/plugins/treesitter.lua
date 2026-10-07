-- カスタムTreesitterパーサーの設定
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      -- User TSUpdateオートコマンドでnorgパーサーを登録
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
          require("nvim-treesitter.parsers").norg = {
            install_info = {
              url = "https://github.com/nvim-neorg/tree-sitter-norg",
              branch = "main",
              files = { "src/parser.c", "src/scanner.c" },
            },
            filetype = "norg",
          }
        end,
      })
    end,
  },
}