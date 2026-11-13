local dap = require("dap")
local dapui = require("dapui")

dap.adapters.netcoredbg = function(callback)
	local command = vim.fn.exepath("netcoredbg")
	if command == "" then
		vim.notify(
			"netcoredbg is required to debug .NET applications; install it and ensure it is on PATH",
			vim.log.levels.ERROR
		)
		return
	end

	callback({
		type = "executable",
		command = command,
		args = { "--interpreter=vscode" },
	})
end

dapui.setup()
dap.listeners.after.event_initialized["dapui_config"] = dapui.open
dap.listeners.before.event_terminated["dapui_config"] = dapui.close
dap.listeners.before.event_exited["dapui_config"] = dapui.close

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: start/continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: step out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: conditional breakpoint" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Debug: terminate" })
vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Debug: toggle REPL" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: toggle UI" })

local initialized = false

vim.api.nvim_create_user_command("EasyDotnet", function()
	if initialized then
		vim.notify("easy-dotnet is already initialized; use :Dotnet", vim.log.levels.INFO)
		return
	end

	require("easy-dotnet").setup({
		picker = "snacks",
		-- Roslyn, ProjX, project mappings, and debugger registration are owned by
		-- the dedicated LSP and nvim-dap configurations.
		lsp = { enabled = false },
		projx_lsp = { enabled = false },
		debugger = { auto_register_dap = false },
		test_runner = {
			auto_start_testrunner = false,
		},
		csproj_mappings = false,
		fsproj_mappings = false,
		enable_filetypes = false,
		auto_bootstrap_namespace = { enabled = false },
	})

	initialized = true
	vim.notify("easy-dotnet initialized; use :Dotnet", vim.log.levels.INFO)
end, { desc = "Initialize easy-dotnet on demand" })
