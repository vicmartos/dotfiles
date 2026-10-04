vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" }, { confirm = false })

local fzf = require("fzf-lua")

fzf.setup({
	"ivy",
	fzf_colors = true,
	ui_select = {},
	winopts = {
		preview = { hidden = true },
	},
})

vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", fzf.helptags, { desc = "Find help" })
vim.keymap.set("n", "<leader>fr", fzf.resume, { desc = "Resume picker" })
vim.keymap.set("n", "<leader>fz", fzf.builtin, { desc = "FzfLua: choose picker" })
vim.keymap.set("n", "<leader>gf", fzf.git_status, { desc = "Git: changed files" })
