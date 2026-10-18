-- Obsidian のボルトは ~/notes。Windows の C:\Users\kento\notes と同じ並びで、Syncthing で揃える。
-- 表示は markdown.lua の render-markdown に任せる。このプラグインの ui は重ねない。
-- 補完はプラグイン内蔵の LSP。LazyVim の blink.cmp がそれを拾う。
--
-- 日次は2枚。本体 daily/YYYY-MM-DD.md は bot の追記先。
-- 人の日次 daily/YYYY-MM-DD-mine.md はそこへリンクする。today は人の日次を開く。
-- コンテナ側 wslc-dev/home/.config/nvim/lua/plugins/obsidian.lua と同じ動き。設定ファイルは共有しない。

local function date_of(note)
  local id = note.id or ""
  if id:match("^%d%d%d%d%-%d%d%-%d%d$") then
    return id
  end
  local name = vim.fn.fnamemodify(tostring(note.path), ":t:r")
  return name:match("^%d%d%d%d%-%d%d%-%d%d$")
end

local function ensure_written(note)
  if note and not note:exists() then
    note:write()
  end
  return note
end

local function ensure_mine(date)
  local Note = require("obsidian.note")
  local note = Note.create({
    id = date .. "-mine",
    verbatim = true,
    aliases = { date .. " mine" },
    tags = { "daily-notes" },
    dir = "daily",
    template = "daily-mine.md",
    scope = "daily-mine",
  })
  return ensure_written(note)
end

local function open_pair(main)
  if main == nil then
    return
  end
  ensure_written(main)
  local date = date_of(main)
  if not date then
    main:open()
    return
  end
  ensure_mine(date):open()
end

local function open_today(data)
  local arg = string.gsub(data.args or "", " ", "")
  local daily = require("obsidian.daily")
  local main
  if arg ~= "" then
    local offset = tonumber(arg)
    if offset ~= nil then
      main = daily.daily({ offset = offset })
    else
      local parsed, err = require("obsidian.date").parse(arg)
      if not parsed then
        require("obsidian.log").err(
          string.format(
            "Invalid argument: %s (expected integer offset or date in format like YYYY-MM-DD)\nErr: %s",
            arg,
            err
          )
        )
        return
      end
      main = daily.daily({ date = os.time(parsed) })
    end
  else
    main = daily.today()
  end
  open_pair(main)
end

local function register_daily_commands()
  local commands = require("obsidian.commands")
  commands.register("today", { nargs = "?", func = open_today })
  commands.register("yesterday", {
    nargs = 0,
    func = function()
      open_pair(require("obsidian.daily").yesterday())
    end,
  })
  commands.register("tomorrow", {
    nargs = 0,
    func = function()
      open_pair(require("obsidian.daily").tomorrow())
    end,
  })
end

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
          path = vim.fn.expand("~/notes"),
        },
      },
      notes_subdir = "notes",
      new_notes_location = "notes_subdir",
      templates = {
        folder = "templates",
        -- 人の日次テンプレートが、ノート id「YYYY-MM-DD-mine」から本体の日付を取る。
        substitutions = {
          daily_id = function(ctx)
            local id = ctx.partial_note and ctx.partial_note.id or ""
            return (id:gsub("%-mine$", ""))
          end,
        },
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
    config = function(_, opts)
      require("obsidian").setup(opts)
      register_daily_commands()
    end,
  },
}
