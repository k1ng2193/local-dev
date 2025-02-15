return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" },
        go = { "goimports" },
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

		vim.keymap.set({ "n", "v" }, "<leader>fm", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 3000,
			})
		end, { desc = "Format" })
	end,
}
