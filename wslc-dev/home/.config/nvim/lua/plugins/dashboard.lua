-- 起動画面。chafa で描いた絵を画面いっぱい（contain）に敷き、Snacks のメニューをその上に重ねる。
-- 絵は chafa の出力を色ごとの extmark に直して、メニューの文字がない場所にだけ描く。
-- 白い部分は透過した PNG なので、Noctty の背景画像は透けたまま。

local img = vim.fn.stdpath("config") .. "/dashboard.png"
-- Noctty の文字マスの幅 / 高さ。正方形の絵が正方形に見える値。
local ratio = 2 / 5
local ns = vim.api.nvim_create_namespace("dashboard_art")
local cache = {} ---@type table<string, {[1]:string, [2]:string?}[][]>

local function chafa(w, h)
	local key = w .. "x" .. h
	if cache[key] then
		return cache[key]
	end
	local res = vim.system({
		"chafa",
		"--probe",
		"off",
		"-f",
		"symbols",
		"--fg-only",
		"-c",
		"full",
		"-O",
		"0",
		"--symbols",
		"sextant+vhalf+block+space",
		"--font-ratio",
		"2/5",
		"--stretch",
		"--work",
		"9",
		"--color-extractor",
		"median",
		"--margin-bottom",
		"0",
		"--margin-right",
		"0",
		"-s",
		key,
		"--view-size",
		key,
		img,
	}, { text = true }):wait()
	if res.code ~= 0 then
		return {}
	end
	local rows = {}
	for line in res.stdout:gmatch("([^\n]*)\n") do
		local cells, fg, i = {}, nil, 1
		while i <= #line do
			local _, e, params, final = line:find("^\27%[([%d;?]*)(%a)", i)
			if e then
				if final == "m" then
					local r, g, b = params:match("38;2;(%d+);(%d+);(%d+)")
					fg = r and string.format("%02x%02x%02x", r, g, b) or nil
				end
				i = e + 1
			else
				local ch = line:match("^[%z\1-\127\194-\244][\128-\191]*", i) or line:sub(i, i)
				cells[#cells + 1] = { ch, fg }
				i = i + #ch
			end
		end
		rows[#rows + 1] = cells
	end
	cache[key] = rows
	return rows
end

-- メニューの文字のかたまり（アイコンと名前、キー）ごとに、左右 1 マスを空けて読みやすくする。
local function blocked_cols(line)
	local blocked, col, first, last = {}, 0, nil, nil
	local function close()
		if first then
			for c = first - 1, last + 1 do
				blocked[c] = true
			end
		end
		first, last = nil, nil
	end
	for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
		local cw = vim.fn.strdisplaywidth(ch)
		if ch ~= " " then
			first = first or col
			last = col + cw - 1
		elseif last and col - last > 2 then
			close()
		end
		col = col + cw
	end
	close()
	return blocked
end

local function render(buf)
	local win = vim.fn.bufwinid(buf)
	if win == -1 then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local W, H = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
	local w = math.min(W, math.floor(H / ratio))
	local h = math.min(H, math.floor(w * ratio))
	local rows = chafa(w, h)
	local top, left = math.floor((H - #rows) / 2), math.floor((W - w) / 2)

	local count = vim.api.nvim_buf_line_count(buf)
	if count < top + #rows then
		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, count, count, false, vim.fn["repeat"]({ "" }, top + #rows - count))
		vim.bo[buf].modifiable = false
		vim.bo[buf].modified = false
	end

	for r, cells in ipairs(rows) do
		local lnum = top + r - 1
		local line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
		local blocked = blocked_cols(line)
		local chunks, start = {}, nil
		local function flush()
			if start and #chunks > 0 then
				vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
					virt_text = chunks,
					virt_text_win_col = start,
					hl_mode = "combine",
					priority = 1,
				})
			end
			chunks, start = {}, nil
		end
		for c, cell in ipairs(cells) do
			local col = left + c - 1
			if cell[1] == " " or not cell[2] or blocked[col] then
				flush()
			else
				local group = "DashboardArt" .. cell[2]
				vim.api.nvim_set_hl(0, group, { fg = "#" .. cell[2] })
				start = start or col
				local prev = chunks[#chunks]
				if prev and prev[2] == group then
					prev[1] = prev[1] .. cell[1]
				else
					chunks[#chunks + 1] = { cell[1], group }
				end
			end
		end
		flush()
	end
end

return {
	{
		"snacks.nvim",
		init = function()
			require("config.image_size").patch()
			vim.api.nvim_create_autocmd("User", {
				pattern = "SnacksDashboardUpdatePost",
				callback = function()
					if vim.fn.executable("chafa") == 0 then
						return
					end
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.bo[buf].filetype == "snacks_dashboard" then
							render(buf)
						end
					end
				end,
			})
		end,
		opts = {
			dashboard = {
				width = 60,
				preset = {
					header = "",
				},
				sections = {
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "startup" },
				},
			},
		},
	},
}
