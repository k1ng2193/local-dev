-- local home_dir = os.getenv("HOME") or "~"

-- local local_lua_path = home_dir .. "/.luarocks/share/lua/5.4/?.lua"

-- package.path = package.path .. ";" .. local_lua_path

require("config.core")
require("config.lazy")
