return {
	"mason-org/mason-lspconfig.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"neovim/nvim-lspconfig",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})
		require("mason-tool-installer").setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"isort", -- python formatter
				"black", -- python formatter
				"eslint_d",
				"jsonlint",
				"yamllint",
				"shfmt",
				"shellcheck",
				"gci",
				"golines",
			},
		})

		require("mason-lspconfig").setup({
			ensure_installed = {
				"bashls",
				"dockerls",
				"docker_compose_language_service",
				"jsonls",
				"ts_ls",
				"lua_ls",
				"sqlls",
				"rust_analyzer",
        "basedpyright",
				"ruff",
				"gopls",
			},
			automatic_enable = true,
		})
	end,
}
