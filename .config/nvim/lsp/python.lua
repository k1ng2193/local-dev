local utils = require("core.utils")

return {
	basedpyright = {
		cmd = { "basedpyright" },
		on_new_config = utils.activate_venv,
		root_dir = function(bufnr, on_dir)
			utils.find_lsp_root_dir(bufnr, on_dir, { "uv.lock", ".venv" })
		end,
		root_markers = { "pyproject.toml", "requirements.txt", ".git" },
		settings = {
			basedpyright = {
				analysis = {
					autoSearchPaths = true,
					diagnosticMode = "openFilesOnly",
					useLibraryCodeForTypes = true,
					typeCheckingMode = "strict",
					reportExplicitAny = false,
					reportUnannotatedClassAttribute = false,
					disableOrganizeImports = true,
					reportUnusedImport = false,
					diagnosticSeverityOverrides = {
						reportArgumentType = "warning",
						reportAttributeAccessIssue = "warning",
						reportOptionalMemberAccess = "warning",
						reportOptionalOperand = "warning",
						reportReturnType = "warning",
						reportUndefinedVariable = "warning",
						reportUnboundVariable = "warning",
						reportUnusedVariable = "warning",
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
					},
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
	},
	ruff = {
		cmd = { "ruff" },
		on_attach = function(client, _)
			if client.name == "ruff" then
				client.server_capabilities.hoverProvider = false
			end
		end,
		root_dir = function(bufnr, on_dir)
			utils.find_lsp_root_dir(bufnr, on_dir, { "uv.lock", ".venv" })
		end,
		root_markers = { "pyproject.toml", "requirements.txt", ".git" },
		settings = {
			-- Complexity (equivalent to --max-complexity)
			-- lint = {
			-- 	enable = false,
			-- },

			-- Line length and complexity
			line_length = 100,
			preview = true,
			hoverProvider = false,

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
}
