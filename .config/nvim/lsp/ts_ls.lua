return {
	cmd = { "typescript-language-server" },
	filetypes = { "js", "ts", "jsx", "tsx" },
	root_markers = { "package.json", "node_modules" },
	settings = {
		typescript = {
			preferences = {
				includePackageJsonAutoImports = "auto",
				includeCompletionsForModuleExports = true,
			},
			suggest = {
				includeCompletionsForModuleExports = true,
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
}
