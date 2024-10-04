-- Get the path to your home directory
local home_dir = os.getenv("HOME") or "~"

-- Construct the full path to your local Lua modules directory
local local_lua_path = home_dir .. "/.luarocks/share/lua/5.4/?.lua"

-- Add the local Lua modules directory to package.path
package.path = package.path .. ";" .. local_lua_path

require("config.core")
require("config.lazy")
