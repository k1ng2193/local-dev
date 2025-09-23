return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

    -- lint.linters.flake8.args = {
    --   "--max-line-length=100",
    --   "--max-complexity=18",
    --   "--select=B,C,E,F,W,T4,B9",
    --   "--ignore=E266,E501,W503,E203,F401",
    -- }

    lint.linters.yamllint.args = {
      "-d",
      "{extends: default, rules: {line-length: {max: 100}}}",
    }

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			-- python = { "ruff" },
			json = { "jsonlint" },
			yaml = { "yamllint" },
      sh = { "shellcheck" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>tl", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
