return {
	"j-morano/buffer_manager.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{
			"<leader>b",
			function()
				require("buffer_manager.ui").toggle_quick_menu()
			end,
			noremap = true,
			silent = true,
			desc = "Open Buffer Manager",
		},
	},
	opts = {},
}
