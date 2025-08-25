return {
	"folke/todo-comments.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
	config = function()
		local todo_comments = require("todo-comments")
		local snacks = require("snacks")

		local keymap = vim.keymap

		keymap.set("n", "<leader>do", function()
			snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
		end, { desc = "Next todo comment" })
		keymap.set("n", "]td", function()
			todo_comments.jump_next()
		end, { desc = "Next todo comment" })

		keymap.set("n", "[td", function()
			todo_comments.jump_prev()
		end, { desc = "Previous todo comment" })

		todo_comments.setup()
	end,
}
