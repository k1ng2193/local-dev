return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".git",
		".luacheckrc",
		".stylua.toml",
		"selene.toml",
		"stylua.toml",
		"selene.yml",
	},
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim", "require" },
			},
		},
	},
  log_level = vim.lsp.protocol.MessageType.Warning,
}
