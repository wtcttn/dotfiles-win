-- Obsidian のボルトは /mnt/notes（Windows の C:\Users\kento\notes）。
-- 表示は markdown.lua の render-markdown に任せる。このプラグインの ui は重ねない。
-- 補完はプラグイン内蔵の LSP。LazyVim の blink.cmp がそれを拾う。

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cmd = "Obsidian",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "notes",
          path = "/mnt/notes",
        },
      },
      notes_subdir = "notes",
      new_notes_location = "notes_subdir",
      templates = {
        folder = "templates",
      },
      -- ファイル名はタイトルのままにする。日本語のノートを slug にしない。
      note_id_func = function(title)
        local name = vim.trim(title or "")
        if name == "" then
          return require("obsidian.builtin").zettel_id()
        end
        return (name:gsub('[\\/:*?"<>|]', "-"))
      end,
      daily_notes = {
        folder = "daily",
        date_format = "YYYY-MM-DD",
        workdays_only = false,
        -- 骨組みはボルトの templates/daily.md。名前は templates.folder からの相対。
        template = "daily.md",
      },
      attachments = {
        folder = "attachments",
      },
      picker = {
        name = "snacks.picker",
      },
      ui = { enable = false },
      footer = { enabled = false },
      statusline = { enabled = false },
    },
  },
}
