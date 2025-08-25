return {
	"stevearc/overseer.nvim",
	keys = {
		{
			"<leader>ot",
			":OverseerToggle<CR>",
			noremap = true,
			silent = true,
			desc = "Toggle Overseer Window",
		},
		{
			"<leader>os",
			function()
				vim.notify("SUCCESS - All tasks have been disposed.", vim.log.levels.INFO, {
					title = "Compiler.nvim",
				})
				local overseer = require("overseer")
				local tasks = overseer.list_tasks({ unique = false })
				for _, task in ipairs(tasks) do
					overseer.run_action(task, "dispose")
				end
			end,
			noremap = true,
			silent = true,
			desc = "Dispose all Oversee Tasks",
		},
	},
	commit = "400e762648b70397d0d315e5acaf0ff3597f2d8b",
	opts = {
		task_list = {
			direction = "bottom",
			min_height = 25,
			max_height = 25,
			default_detail = 1,
		},
	},
}
