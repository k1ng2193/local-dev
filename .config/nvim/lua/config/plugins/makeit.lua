return { -- This plugin
  "Zeioth/makeit.nvim",
	keys = {
		{ "<leader>mo", ":MakeitOpen<CR>", noremap = true, silent = true, desc = "Open Makefile Window" },
		{ "<leader>mt", ":MakeitToggleResults<CR>", noremap = true, silent = true, desc = "Toggle Makefile Process Results" },
		{ "<leader>mr", ":MakeitRedo<CR>", noremap = true, silent = true, desc = "Re-run Makefile Process" },
	},
  cmd = {"MakeitOpen", "MakeitToggleResults", "MakeitRedo"},
  dependencies = { "stevearc/overseer.nvim" },
  opts = {},
}
