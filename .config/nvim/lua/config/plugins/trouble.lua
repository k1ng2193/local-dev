return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
	},
	config = function()
		local trouble = require("trouble")

		vim.keymap.set("n", "<leader>xd", function()
			trouble.toggle("diagnostics")
		end, { desc = "Toggle Diagnostics Window" })
		vim.keymap.set("n", "]x", function()
			trouble.next("diagnostics")
			trouble.jump("diagnostics")
		end, { desc = "Next Trouble Diagnostic" })
		vim.keymap.set("n", "[x", function()
			trouble.prev("diagnostics")
			trouble.jump("diagnostics")
		end, { desc = "Previous Trouble Diagnostic" })
		vim.keymap.set("n", "<leader>qf", function()
			trouble.toggle("quickfix")
		end, { desc = "Toggle Quickfix Window" })
		vim.keymap.set("n", "<leader>qc", function()
			vim.cmd(":cexpr []")
			trouble.close("quickfix")
		end, { noremap = true, silent = true, desc = "Clear QuickFix List" })
		vim.keymap.set("n", "<leader>xl", function()
			trouble.toggle("lsp")
		end, { desc = "Toggle LSP Window" })
	end,
}
