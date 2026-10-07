return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- We'd like this plugin to load first out of the rest
    config = true,   -- This automatically runs `require("luarocks-nvim").setup()`
  },
  {
    "nvim-neorg/neorg",
    dependencies = { "luarocks.nvim" },
    lazy = false,
    version = false,
    opts = {
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {},
        ["core.dirman"] = {
          config = {
            workspaces = {
              public = "~/public_notes",
              private = "~/private_notes",
            },
          },
        },
        ["core.keybinds"] = {
          config = {
            -- 必要最小限のキーバインドのみ設定
            hook = function(keybinds)
              -- ノート編集用のキーバインド（<LocalLeader>n プレフィックス）
              keybinds.map("norg", "n", "<LocalLeader>nn", "<cmd>Neorg toc<cr>", { desc = "Table of Contents" })
              keybinds.map("norg", "n", "<LocalLeader>nt", "<cmd>Neorg toggle-concealer<cr>", { desc = "Toggle Concealer" })

              -- タスク管理（<LocalLeader>t プレフィックスをneorg専用に）
              keybinds.map("norg", "n", "<LocalLeader>ntd", "<Plug>(neorg.qol.todo-items.todo.task-done)",
                { desc = "Task Done" })
              keybinds.map("norg", "n", "<LocalLeader>ntu", "<Plug>(neorg.qol.todo-items.todo.task-undone)",
                { desc = "Task Undone" })
              keybinds.map("norg", "n", "<LocalLeader>ntp", "<Plug>(neorg.qol.todo-items.todo.task-pending)",
                { desc = "Task Pending" })
              keybinds.map("norg", "n", "<LocalLeader>ntc", "<Plug>(neorg.qol.todo-items.todo.task-cancelled)",
                { desc = "Task Cancelled" })

              -- タスクサイクル（Ctrl+Space の代わり）
              keybinds.map("norg", "n", "<LocalLeader>nts", "<Plug>(neorg.qol.todo-items.todo.task-cycle)",
                { desc = "Task Cycle" })

              -- リスト操作（< > の代わり）
              keybinds.map("norg", "n", "<LocalLeader>nli", "<Plug>(neorg.pivot.list.invert)", { desc = "List Invert" })
              keybinds.map("norg", "n", "<LocalLeader>nlt", "<Plug>(neorg.pivot.list.toggle)", { desc = "List Toggle" })

              -- プロモート/デモート（< > の代わり）
              keybinds.map("norg", "n", "<LocalLeader>n>", "<Plug>(neorg.promo.promote)", { desc = "Promote" })
              keybinds.map("norg", "n", "<LocalLeader>n<", "<Plug>(neorg.promo.demote)", { desc = "Demote" })
              keybinds.map("norg", "v", "<LocalLeader>n>", "<Plug>(neorg.promo.promote.range)", { desc = "Promote Range" })
              keybinds.map("norg", "v", "<LocalLeader>n<", "<Plug>(neorg.promo.demote.range)", { desc = "Demote Range" })

              -- その他
              keybinds.map("norg", "n", "<LocalLeader>ncm", "<Plug>(neorg.looking-glass.magnify-code-block)",
                { desc = "Magnify Code Block" })
              keybinds.map("norg", "n", "<LocalLeader>nid", "<Plug>(neorg.tempus.insert-date)", { desc = "Insert Date" })
            end,
          },
        },
      },
    },
  },
}
