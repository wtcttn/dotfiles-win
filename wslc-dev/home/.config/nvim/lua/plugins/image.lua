-- 画像ファイルと、マークダウンに埋め込んだ画像を端末に描く。
-- WezTerm は Kitty graphics の一部だけなので、カーソルを置いた行の浮き窓になる。
-- Noctty（Ghostty）は本文の中に描ける。名前を snacks が拾えないときは force で浮き窓に落とす。
-- ノートの ![[名前]] は obsidian の添付解決に渡す。それ以外はファイルからの相対パス。

local image_exts = { "png", "jpg", "jpeg", "gif", "webp", "avif", "bmp" }

local function insert_markdown_image(path)
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
  local rel = vim.fs.relpath(dir, path) or path
  local name = vim.fs.basename(path)
  vim.api.nvim_put({ string.format("![%s](%s)", name, rel) }, "c", true, true)
end

local function embed_image()
  local cwd = vim.fn.expand("%:p:h")
  if cwd == "" then
    cwd = vim.uv.cwd()
  end
  if vim.b.obsidian_buffer then
    cwd = "/mnt/notes"
  end
  Snacks.picker.files({
    cwd = cwd,
    ft = image_exts,
    title = "画像を埋め込む",
    confirm = function(picker, item)
      picker:close()
      local path = item and item.file
      if not path or vim.fn.filereadable(path) == 0 then
        return
      end
      if vim.b.obsidian_buffer then
        require("obsidian.actions").add_attachment(path)
        return
      end
      insert_markdown_image(path)
    end,
  })
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>oi", embed_image, desc = "画像を埋め込む", ft = "markdown" },
    },
    opts = {
      image = {
        enabled = true,
        -- Noctty が自分の名前で応答しても、プロトコル自体は使える。
        force = true,
        doc = {
          enabled = true,
          inline = true,
          float = true,
          max_width = 60,
          max_height = 20,
        },
        math = { enabled = false },
        resolve = function(file, src)
          local ok, resolved = pcall(function()
            local api = require("obsidian.api")
            if not api.path_is_note(file) or src:find("[/\\]") then
              return nil
            end
            local path = tostring(api.resolve_attachment_path(src))
            if vim.fn.filereadable(path) == 1 then
              return path
            end
          end)
          if ok then
            return resolved
          end
        end,
      },
    },
  },
}
