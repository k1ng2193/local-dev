local M = {}

local utils = require("core.utils")

--- Given a path, open the file, extract all the Makefile keys,
--  and return them as a list.
---@param path string
---@return table options A telescope options list like
--{ { text: "1 - all", value="all" }, { text: "2 - hello", value="hello" } ...}
local function get_makefile_options(path)
	local options = {}

	-- Open the Makefile for reading
	local file = io.open(path, "r")

	if file then
		local in_target = false
		local count = 0

		-- Iterate through each line in the Makefile
		for line in file:lines() do
			-- Check for lines starting with a target rule (e.g., "target: dependencies")
			local target = line:match("^([%w%-_]+):.*$")
			if target then
				in_target = true
				count = count + 1
				-- Exclude the ":" and add the option to the list with text and value fields
        local target_name = line:match("^([%w%-_]+):")
				table.insert(options, { text = count .. " - " .. target_name, value = target_name })
			elseif in_target then
				-- If we're inside a target block, stop adding options
				in_target = false
			end
		end

		-- Close the Makefile
		file:close()
	else
		vim.notify("Unable to open a Makefile in the current working dir.", vim.log.levels.ERROR, {
			title = "Makeit.nvim",
		})
	end

	return options
end

local function run_makefile(option)
	local overseer = require("overseer")
	local final_message = "--task finished--"
	local task = overseer.new_task({
		name = "- Make interpreter",
		strategy = {
			"orchestrator",
			tasks = {
				{
					"shell",
					name = "- Run makefile → make " .. option,
					cmd = "make "
						.. option -- run
						.. " && echo make "
						.. option -- echo
						.. " && echo '"
						.. final_message
						.. "'",
				},
			},
		},
	})
	task:start()
	overseer.window.open({ enter = true, direction = "bottom" })
end

function M.make_redo()
	if _G.makeit_redo == nil then
		vim.notify("Open makeit and select an option before doing redo.", vim.log.levels.INFO, {
			title = "Makeit.nvim",
		})
		return
	end
	run_makefile(_G.makeit_redo)
end

---@return table
function M.make_picker()
	return {
		title = "Makeit",
		finder = function()
			local uv = vim.uv or vim.loop
			local cwd = vim.fs.normalize(uv.cwd() or ".")
			local path = utils.os_path(cwd .. "/Makefile")
			local options = {}
			if path ~= nil then
				options = get_makefile_options(path)
			end

			return options
		end,
		format = "text",
		layout = { preview = false },
		confirm = function(picker)
			local item = picker:current()
			if not item and not item.value then
				return
			end
			_G.makeit_redo = item.value
			run_makefile(item.value)
		end,
	}
end

return M
