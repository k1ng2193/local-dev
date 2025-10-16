return {
	cmd = { "ruff" },
	on_attach = function(client, _)
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end
	end,
	root_dir = function(bufnr, on_dir)
		local root_markers = { "uv.lock", ".venv", ".git" }
		local current_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
		local root_path = vim.fs.find(root_markers, { upward = true, stop = current_dir })
		if root_path then
			on_dir(vim.fs.dirname(root_path[1]))
		end
	end,
	root_markers = { "pyproject.toml", "requirements.txt" },
	settings = {
		-- Complexity (equivalent to --max-complexity)
		-- lint = {
		-- 	enable = false,
		-- },

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
}
