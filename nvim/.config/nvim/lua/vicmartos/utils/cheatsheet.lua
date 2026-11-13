local M = {}

-- Resolve from this module so the viewer also works with a symlinked config
-- and when Neovim starts outside the dotfiles directory.
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h:h")
local window

function M.open()
	if window and vim.api.nvim_win_is_valid(window) then
		vim.api.nvim_set_current_win(window)
		return
	end

	local ok, lines = pcall(vim.fn.readfile, config_dir .. "/KEYMAPS.md")
	if not ok then
		vim.notify("Cannot read keymap cheatsheet: " .. config_dir .. "/KEYMAPS.md", vim.log.levels.ERROR)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].modifiable = false
	local width = math.max(1, math.min(120, vim.o.columns - 4))
	local height = math.max(1, math.min(math.floor(vim.o.lines * 0.8), vim.o.lines - 4))
	window = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.max(0, math.floor((vim.o.columns - width) / 2) - 1),
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		style = "minimal",
		border = "rounded",
		title = " Keymaps · q / Esc to close ",
		title_pos = "center",
	})
	vim.wo[window].wrap = false
	vim.wo[window].conceallevel = 0
	vim.wo[window].winblend = 0
	local win = window
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end, { buffer = buf, silent = true, desc = "Close keymap cheatsheet" })
	end
end

return M
