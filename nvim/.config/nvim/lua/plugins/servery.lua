vim.pack.add({ "https://github.com/wurli/servery.nvim" }, { confirm = false })

local servery = require("servery")
local M = {}

local project_roots = { "~/personal", "~/work", "~/Work", "~/git" }

function M.project_dirs()
	local dirs = {}
	for _, root in ipairs(project_roots) do
		root = vim.fn.expand(root)
		if vim.fn.isdirectory(root) == 1 then
			for name in vim.fs.dir(root) do
				if name:sub(1, 1) ~= "." then
					local path = vim.fs.joinpath(root, name)
					if vim.fn.isdirectory(path) == 1 then
						dirs[#dirs + 1] = path
					end
				end
			end
		end
	end
	return dirs
end

servery.setup({
	dirs = M.project_dirs,
	ui = { provider = "fzf", prompt = "Session" },
})

vim.keymap.set("n", "<leader>pp", "<cmd>Sv<cr>", { desc = "Sessions: switch session" })

return M
