-- wslc の PTY は文字数だけ返して画素が 0 になる。0 のままだと画像の配置が壊れ、絵が出ない。
-- 端末へセルの画素サイズを問い合わせ、無応答なら 9x18 で描く。
-- snacks の init は起動画面が使うので、そこは触らず、起動画面の init からこれを呼ぶ。

local M = {}

function M.patch()
  local ok, terminal = pcall(require, "snacks.image.terminal")
  if not ok or terminal._wslc_size then
    return
  end
  terminal._wslc_size = true
  local orig = terminal.size
  local cached ---@type snacks.image.terminal.Dim?

  local function query_cell()
    if not vim.api.nvim_ui_send then
      return nil
    end
    local got ---@type { w: number, h: number }?
    local id = vim.api.nvim_create_autocmd("TermResponse", {
      callback = function(ev)
        local seq = ev.data and ev.data.sequence or ""
        local h, w = seq:match("6;(%d+);(%d+)t")
        if not h then
          return
        end
        got = { h = tonumber(h), w = tonumber(w) }
        return true
      end,
    })
    vim.api.nvim_ui_send("\027[16t")
    vim.wait(400, function()
      return got ~= nil
    end, 10)
    pcall(vim.api.nvim_del_autocmd, id)
    if got and got.w > 0 and got.h > 0 then
      return got.w, got.h
    end
  end

  function terminal.size()
    if cached and cached.cell_width > 0 and cached.cell_height > 0 then
      cached.columns = vim.o.columns
      cached.rows = vim.o.lines
      cached.width = cached.columns * cached.cell_width
      cached.height = cached.rows * cached.cell_height
      return cached
    end
    local size = orig()
    if size.cell_width > 0 and size.cell_height > 0 and size.width > 0 and size.height > 0 then
      cached = size
      return size
    end
    local queried, cw, ch = pcall(query_cell)
    if not queried then
      cw, ch = nil, nil
    end
    cw = (cw and cw > 0) and cw or 9
    ch = (ch and ch > 0) and ch or 18
    cached = {
      width = vim.o.columns * cw,
      height = vim.o.lines * ch,
      columns = vim.o.columns,
      rows = vim.o.lines,
      cell_width = cw,
      cell_height = ch,
      scale = math.max(1, cw / 8),
    }
    return cached
  end
end

return M
