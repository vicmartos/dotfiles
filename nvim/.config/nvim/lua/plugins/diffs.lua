vim.g.diffs = {
	integrations = {
		fugitive = true,
	},
}

vim.pack.add({ "https://github.com/barrettruth/diffs.nvim" }, { confirm = false })

vim.keymap.set("n", "<leader>gr", "<cmd>Diff review HEAD<cr>", { desc = "Git: review changes since HEAD" })
