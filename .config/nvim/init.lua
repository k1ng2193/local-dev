vim.api.nvim_set_hl(0, "LineNr", { fg = "white" })
-- local home_dir = os.getenv("HOME") or "~"

-- local local_lua_path = home_dir .. "/.luarocks/share/lua/5.4/?.lua"

-- package.path = package.path .. ";" .. local_lua_path
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python_provider = 0

require("config.autocmds")
require("config.usercmds")
require("config.options")
require("config.remap")
require("core.lsp")
require("core.lazy")
