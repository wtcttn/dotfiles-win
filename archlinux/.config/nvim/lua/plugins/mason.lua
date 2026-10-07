return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- bash LSP
        "bash-language-server",
        -- bash linter
        "shellcheck",
        -- bash format
        "shfmt",
      },
    },
  },
}
