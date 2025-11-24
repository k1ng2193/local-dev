return {
	cmd = { "basedpyright" },
	on_new_config = function()
		local utils = require("core.utils")

		-- Activate virtualenv before LSP starts
		utils.activate_venv()
	end,
	root_dir = function(bufnr, on_dir)
		local root_markers = { "uv.lock", ".venv" }
		local current_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
		local root_path = vim.fs.find(root_markers, { upward = true, stop = current_dir })
		if root_path then
			on_dir(vim.fs.dirname(root_path[1]))
		end
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
}
