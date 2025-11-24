return {
	"folke/todo-comments.nvim",
	optional = true,
	keys = {
		{
			"<leader>do",
			function()
				Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
			end,
			desc = "Find TODO/FIX/FIXME",
		},
	},
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
	config = function()
		local todo_comments = require("todo-comments")
		local keymap = vim.keymap

		keymap.set("n", "]td", function()
			todo_comments.jump_next()
		end, { desc = "Next todo comment" })

		keymap.set("n", "[td", function()
			todo_comments.jump_prev()
		end, { desc = "Previous todo comment" })

		todo_comments.setup()
	end,
}
