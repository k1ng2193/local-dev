return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier", "eslint_d" },
				typescript = { "prettier", "eslint_d" },
				javascriptreact = { "prettier", "eslint_d" },
				typescriptreact = { "prettier", "eslint_d" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" },
				go = { "gci", "golines" },
				cpp = { "clang-format" },
				h = { "clang-format" },
				m = { "clang-format" },
				mm = { "clang-format" },
				hpp = { "clang-format" },
			},
			-- format_on_save = {
			--     lsp_fallback = true,
			--     async = false,
			--     timeout_ms = 3000,
			-- },
		})

		-- conform.formatters.injected = {
		-- 	options = {
		-- 		lang_to_ext = {
		-- 			bash = "sh",
		-- 			javascript = "js",
		-- 			python = "py",
		-- 			rust = "rs",
		-- 			json = "json",
		-- 			yaml = "yaml",
		-- 			lua = "lua",
		-- 			typescript = "ts",
		-- 		},
		-- 	},
		-- }
		--
		conform.formatters.prettier = {
			options = {
				ft_parsers = {
					javascript = "babel",
					javascriptreact = "babel",
					typescript = "typescript",
					typescriptreact = "typescript",
					css = "css",
					html = "html",
					json = "json",
					jsonc = "json",
					yaml = "yaml",
				},
			},
		}

		conform.formatters.isort = {
			prepend_args = { "--profile", "black", "--filter-files" },
		}

		conform.formatters.black = {
			prepend_args = { "--line-length=100" },
		}

		conform.formatters.shfmt = {
			prepend_args = { "-i", "2" },
			stdin = true,
		}

		conform.formatters.gci = {
			command = "gci",
			args = {
				"write",
				"--skip-generated",
				"-s",
				"standard",
				"-s",
				"blank",
				"-s",
				"default",
				"-s",
				"alias",
				"-s",
				"localmodule",
				"$FILENAME",
			},
			stdin = false,
			cwd = function(self, ctx)
				-- Find the go.mod file starting from current file's directory
				local util = require("conform.util")
				return util.root_file({ "go.mod" })(self, ctx)
			end,
		}

		conform.formatters.golines = {
			prepend_args = { "--ignore-generated", "--max-len=120" },
		}

		conform.formatters.clang_format = {
			args = { "--style=Google" },
		}

		vim.keymap.set({ "n", "v" }, "<leader>fm", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 3000,
			})
		end, { desc = "Format" })
	end,
}
