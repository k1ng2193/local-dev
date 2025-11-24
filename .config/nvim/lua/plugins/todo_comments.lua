return {
	"folke/todo-comments.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local todo = require("todo-comments")
		todo.setup()

		vim.keymap.set("n", "]td", function()
			todo.jump_next()
		end, { desc = "Next TODO" })
		vim.keymap.set("n", "[td", function()
			todo.jump_prev()
		end, { desc = "Previous TODO" })
	end,
}
