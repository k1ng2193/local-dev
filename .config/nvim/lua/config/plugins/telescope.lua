return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = function(...)
							require("telescope.actions").send_to_qflist(...)
							require("trouble").open("quickfix")
						end,
					},
				},
			},
			pickers = {
				find_files = {
					file_ignore_patterns = {
						"node_modules",
						".git/",
						".venv",
						".idea",
					},
					hidden = true,
					no_ignore = true,
				},
				live_grep = {
					file_ignore_patterns = {
						"node_modules",
						".git/",
						".venv",
						".idea",
					},
					additional_args = function()
						return { "--hidden", "--no-ignore" }
					end,
				},
			},
		})

		telescope.load_extension("fzf")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search Files" })
		vim.keymap.set("n", "<leader>fg", builtin.git_status, { desc = "Search Git Status" })
		vim.keymap.set("n", "<leader>fx", builtin.git_stash, { desc = "Search Git Stash" })
		vim.keymap.set("n", "<leader>fc", builtin.git_commits, { desc = "Search Git Commits" })
		vim.keymap.set("n", "<leader>ft", builtin.git_branches, { desc = "Search Git Branches" })
		vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Search String" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Search Buffer" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Search Keymaps" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search Help" })
	end,
}
