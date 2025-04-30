return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		-- "ray-x/lsp_signature.nvim",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local keymap = vim.keymap

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Set up lsp_signature
				-- require("lsp_signature").on_attach({
				--     bind = true, -- Bind lsp_signature to keybindings
				--     handler_opts = {
				--         border = "single"
				--     },
				--     hint_enable = true,
				--     hint_prefix = "👀 ",
				-- })

				local opts = { buffer = ev.buf, silent = true }

				opts.desc = "Hover Window"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Go To Definition"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

				opts.desc = "Go To Declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Go To Implementation"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Go To Type Definition"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "Go To References"
				keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)

				opts.desc = "Signature Help"
				keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)

				opts.desc = "Rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				-- opts.desc = "Format"
				-- keymap.set({ "n", "x" }, "<leader>fm", function() vim.lsp.buf.format({ async = true }) end, opts)
				--
				opts.desc = "Code Action"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Show Buffer Diagnostics"
				keymap.set("n", "bd", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show Line Diagnostics"
				keymap.set("n", "gl", vim.diagnostic.open_float, opts)

				opts.desc = "Go To Previous Diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go To Next Diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		local lsp_capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"bashls",
				"dockerls",
				"docker_compose_language_service",
				"jsonls",
				"ts_ls",
				"lua_ls",
				"sqlls",
				"rust_analyzer",
				"pyright",
				"ruff",
				"gopls",
			},
		})

		local utils = require("config.core.utils")
		mason_lspconfig.setup_handlers({
			function(server)
				lspconfig[server].setup({
					capabilities = lsp_capabilities,
				})
			end,
			["gopls"] = function()
				lspconfig["gopls"].setup({
					capabilities = lsp_capabilities,
					root_dir = lspconfig.util.root_pattern("go.mod"),
					settings = {
						gopls = {
							buildFlags = { "-tags=dev" },
							staticcheck = true,
							usePlaceholders = true, -- enables placeholder parameters
							completeUnimported = true, -- autocomplete unimported packages
						},
					},
				})
			end,
			["ts_ls"] = function()
				lspconfig["ts_ls"].setup({
					capabilities = lsp_capabilities,
					settings = {
						typescript = {
							inlayHints = {
								includeInlayEnumMemberValueHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayParameterNameHints = true,
								includeInlayParameterNameHintsWhenArgumentMatchesName = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayVariableTypeHints = true,
							},
						},
						javascript = {
							inlayHints = {
								includeInlayEnumMemberValueHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayParameterNameHints = true,
								includeInlayParameterNameHintsWhenArgumentMatchesName = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayVariableTypeHints = true,
							},
						},
					},
				})
			end,
			["lua_ls"] = function()
				lspconfig["lua_ls"].setup({
					capabilities = lsp_capabilities,
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				})
			end,
			["pyright"] = function()
				lspconfig["pyright"].setup({
					on_new_config = function()
						-- Activate virtualenv before LSP starts
						utils.activate_venv()
					end,
					capabilities = lsp_capabilities,
					settings = {
						pyright = {
							disableOrganizeImports = true,
						},
						python = {
							analysis = {
								-- ignore = { "*" },
								diagnosticSeverityOverrides = {
									-- reportMissingImports = "none",
									-- reportMissingTypeStubs = "none",
									-- reportGeneralTypeIssues = "error",
									-- reportFunctionMemberAccess = "warning",
									-- reportPrivateUsage = "warning",
									-- reportUnknownParameterType = "warning",
									-- reportUnknownArgumentType = "warning",
									-- reportUnknownLambdaType = "warning",
									-- reportUnknownVariableType = "warning",
									-- reportUnknownMemberType = "error",
									-- reportMissingTypeArgument = "warning",
									-- reportInvalidTypeVarUse = "error",
									-- reportCallInDefaultInitializer = "none",
									-- reportUnnecessaryIsInstance = "none",
									-- reportUnnecessaryCast = "none",
									-- reportUnnecessaryComparison = "none",
									-- reportAssertAlwaysTrue = "none",
									-- reportSelfClsParameterName = "none",
									-- reportImplicitStringConcatenation = "none",
									-- reportUnsupportedDunderAll = "none",
									-- reportUnusedCallResult = "none",
									-- reportUnusedCoroutine = "none",
									-- reportUninitializedInstanceVariable = "warning",
									reportArgumentType = "warning",
									reportAttributeAccessIssue = "warning",
									reportOptionalMemberAccess = "warning",
									reportOptionalOperand = "warning",
									reportReturnType = "warning",
									reportUndefinedVariable = "warning",
									reportUnboundVariable = "warning",
									reportUnusedImport = "none",
									reportUnusedVariable = "warning", -- or anything
								},
								typeCheckingMode = "standard",
								useLibraryCodeForTypes = true,
								-- reportMissingImports = false,
								-- reportMissingTypeStubs = false,
								-- reportGeneralTypeIssues = true,
								-- reportFunctionMemberAccess = true,
								-- reportPrivateUsage = true,
								-- reportUnknownParameterType = true,
								-- reportUnknownArgumentType = true,
								-- reportUnknownLambdaType = true,
								-- reportUnknownVariableType = true,
								-- reportUnknownMemberType = true,
								-- reportMissingTypeArgument = true,
								-- reportInvalidTypeVarUse = true,
								-- reportCallInDefaultInitializer = false,
								-- reportUnnecessaryIsInstance = false,
								-- reportUnnecessaryCast = false,
								-- reportUnnecessaryComparison = false,
								-- reportAssertAlwaysTrue = false,
								-- reportSelfClsParameterName = false,
								-- reportImplicitStringConcatenation = false,
								-- reportUnsupportedDunderAll = false,
								-- reportUnusedCallResult = false,
								-- reportUnusedCoroutine = false,
								-- reportUninitializedInstanceVariable = true,
							},
							inlayHints = {
								includeInlayEnumMemberValueHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayParameterNameHints = true,
								includeInlayParameterNameHintsWhenArgumentMatchesName = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayVariableTypeHints = true,
							},
						},
					},
				})
			end,
			["ruff"] = function()
				lspconfig["ruff"].setup({
					-- cmd = { vim.fn.stdpath("data") .. "/mason/bin/ruff" },
					init_options = {
						settings = {
							-- Complexity (equivalent to --max-complexity)
							lint = {
								enable = false,
							},

							-- Line length and complexity
							line_length = 100,
							preview = true,

							-- Selected and ignored rules
							select = {
								"B", -- flake8-bugbear
								"C", -- mccabe/complexity
								"E", -- pycodestyle errors
								"F", -- pyflakes
								"W", -- pycodestyle warnings
								"T4", -- type checking
								"B9", -- bugbear opinions
							},
							ignore = {
								"E266", -- too many leading '#' for block comment
								"E501", -- line too long
								"W503", -- line break before binary operator
								"E203", -- whitespace before ':'
								"F401", -- unused imports
								"F841", -- unused variable
							},
						},
					},
					capabilities = lsp_capabilities,
					on_attach = function(client, _)
						if client.name == "ruff" then
							client.server_capabilities.hoverProvider = false
						end
					end,
				})
			end,
		})
	end,
}
