return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		-- dashboard = { enabled = true },
		-- indent = { enabled = true },
		-- input = { enabled = true },
		-- notifier = { enabled = true },
		-- quickfile = { enabled = true },
		-- scroll = { enabled = true },
		-- statuscolumn = { enabled = true },
		-- words = { enabled = true },
		-- This is the important part for your issue:
		bigfile = {
			enabled = true,
			notify = true, -- show notification when big file detected
			size = 1.5 * 1024 * 1024, -- 1.5MB
			line_length = 1000, -- average line length (useful for minified files)
			-- Enable or disable features when big file detected
			---@param ctx {buf: number, ft:string}
			setup = function(ctx)
				if vim.fn.exists(":NoMatchParen") ~= 0 then
					vim.cmd([[NoMatchParen]])
				end
				Snacks.util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
				vim.b.minianimate_disable = true
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(ctx.buf) then
						vim.bo[ctx.buf].syntax = ctx.ft
					end
				end)
			end,
		},
		picker = {
      enabled = true,
			sources = {
				makeit = require("core.makeit").make_picker(),
			},
			ui_select = true,
			matcher = {
				fuzzy = true, -- use fuzzy matching
				smartcase = true, -- use smartcase
				ignorecase = true, -- use ignorecase
				sort_empty = false, -- sort results when the search string is empty
				filename_bonus = true, -- give bonus for matching file names (last part of the path)
				file_pos = true, -- support patterns like `file:line:col` and `file:line`
				-- the bonusses below, possibly require string concatenation and path normalization,
				-- so this can have a performance impact for large lists and increase memory usage
				cwd_bonus = false, -- give bonus for matching files in the cwd
				frecency = false, -- frecency bonus
				history_bonus = false, -- give more weight to chronological order
			},
			sort = {
				-- default sort is by score, text length and index
				fields = { "score:desc", "#text", "idx" },
			},
			find = {
				ignore_patterns = {
					"node_modules",
					".git/",
					".venv",
					".idea",
					".jsbundle",
					".ios.js",
				},
			},
			win = {
				input = {
					keys = {
						["<c-x>"] = { "edit_split", mode = { "i", "n" } },
					},
				},
			},
			actions = {
				qflist = function(picker)
					picker:close()
					local sel = picker:selected()
					local items = #sel > 0 and sel or picker:items()

					local qf = {} ---@type vim.quickfix.entry[]
					for _, item in ipairs(items) do
						qf[#qf + 1] = {
							filename = require("snacks").picker.util.path(item),
							bufnr = item.buf,
							lnum = item.pos and item.pos[1] or 1,
							col = item.pos and item.pos[2] + 1 or 1,
							end_lnum = item.end_pos and item.end_pos[1] or nil,
							end_col = item.end_pos and item.end_pos[2] + 1 or nil,
							text = item.line or item.comment or item.label or item.name or item.detail or item.text,
							pattern = item.search,
							valid = true,
						}
					end

					vim.fn.setqflist(qf)
					require("trouble").open("quickfix")
				end,
			},
		},
	},
	config = function(_, opts)
		local snacks = require("snacks")
		snacks.setup(opts)

		-- Your keymaps translated
		vim.keymap.set("n", "<leader><leader>", function()
			snacks.picker.smart()
		end, { desc = "Smart Find Files" })
		vim.keymap.set("n", "<leader>ff", function()
			snacks.picker.files()
		end, { desc = "Search Files" })
		vim.keymap.set("n", "<leader>fg", function()
			snacks.picker.git_status()
		end, { desc = "Search Git Status" })
		vim.keymap.set("n", "<leader>fx", function()
			snacks.picker.git_stash()
		end, { desc = "Search Git Stash" })
		vim.keymap.set("n", "<leader>gl", function()
			snacks.picker.git_log()
		end, { desc = "Search Git Log" })
		vim.keymap.set("n", "<leader>ft", function()
			snacks.picker.git_branches()
		end, { desc = "Search Git Branches" })
		vim.keymap.set("n", "<leader>gd", function()
			snacks.picker.git_diff()
		end, { desc = "Search Git Log" })
		vim.keymap.set("n", "<leader>fs", function()
			snacks.picker.grep()
		end, { desc = "Search String" })
		vim.keymap.set("n", "<leader>fb", function()
			snacks.picker.buffers()
		end, { desc = "Search Buffer" })
		vim.keymap.set("n", "<leader>fk", function()
			snacks.picker.keymaps()
		end, { desc = "Search Keymaps" })
		vim.keymap.set("n", "<leader>fh", function()
			snacks.picker.help()
		end, { desc = "Search Help" })
		vim.keymap.set("n", "<leader>rg", function()
			snacks.picker.registers()
		end, { desc = "Search Registers" })
		vim.keymap.set("n", "<leader>mp", function()
			snacks.picker.makeit()
		end, { desc = "Open Makefile Picker" })

		-- LSP keymaps
		vim.keymap.set("n", "gd", function()
			snacks.picker.lsp_definitions()
		end, { desc = "Go To Definition" })
		vim.keymap.set("n", "gi", function()
			snacks.picker.lsp_implementations()
		end, { desc = "Go To Implementation" })
		vim.keymap.set("n", "gt", function()
			snacks.picker.lsp_type_definitions()
		end, { desc = "Go To Type Definition" })
		vim.keymap.set("n", "gr", function()
			snacks.picker.lsp_references()
		end, { desc = "Go To References" })
		vim.keymap.set("n", "bd", function()
			snacks.picker.diagnostics()
		end, { desc = "Show Buffer Diagnostics" })
	end,
}
