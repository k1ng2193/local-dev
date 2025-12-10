local utils = require("core.utils")

return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_dir = function(bufnr, on_dir)
		utils.find_lsp_root_dir(bufnr, on_dir, { "lazy-lock.json" })
	end,
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
        path = {
          "lua/?.lua",
          "lua/?/init.lua",
        },
			},
			diagnostics = {
				globals = { "vim", "require" },
				disable = { "unused-local" },
			},
		},
	},
	log_level = vim.lsp.protocol.MessageType.Warning,
}
