local M = {}

---@param input_config table
---@param input_prompt table
function M.mount_input(input_config, input_prompt)
	local Input = require("nui.input")

	local input = Input(input_config, input_prompt)
	input:mount()

	input:map("n", "<ESC>", function()
		input:unmap("n", "<ESC>")
		input:unmap("n", "<leader><BS>")
		input:unmount()
	end, { noremap = true, silent = true })
	input:map("n", "<leader><BS>", function()
		input:unmap("n", "<ESC>")
		input:unmap("n", "<leader><BS>")
		input:unmount()
	end, { noremap = true, silent = true })
end

-- Function to read the content of a file
---@param path string
---@return string | nil
function M.read_file(path)
	local file = io.open(path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		return content
	else
		return
	end
end

---@param command string
---@return string
local function run_command(command)
	local handle = io.popen(command)
	if not handle then
		-- Error occurred while executing the command
		error("Error: Unable to execute command: " .. command) -- End the process
	end

	local result = handle:read("*a")
	handle:close()

	return result
end

---@param command string
---@return string
function M.execute_command(command)
	local ok, result = pcall(run_command, command)
	assert(ok, result)

	return result
end
--
-- Function to open a URL in the default web browser
function M.open_url(url)
	-- Construct the shell command to open the URL
	local command = string.format("open %s", url) -- macOS

	-- Execute the shell command asynchronously
	vim.fn.jobstart(command, {
		detach = true, -- Detach the process from Neovim
		on_exit = function(_, _, _)
			-- Optional: Handle the on_exit event if needed
		end,
	})
end

---@param opts table | nil
---@param new_lines table | nil
function M.update_popup_content(opts, new_lines)
	local Popup = require("nui.popup")
	local event = require("nui.utils.autocmd").event
	local default_popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
		},
		position = {
			row = "100%",
			col = 0,
		},
		size = {
			width = "50%",
			height = "100%",
		},
		anchor = "NW",
		relative = "editor",
	})
	local default_opts = { popup = default_popup, event = event.BufLeave }

	local config = vim.tbl_extend("keep", opts or {}, default_opts)
	if not config.popup.mounted then
		local popup = config.popup

		popup:mount()

		popup:map("n", "<ESC>", function()
			if config.event then
				popup:off(config.event)
			end
			popup:unmap("n", "<ESC>")
			popup:unmap("n", "<leader><BS>")
			popup:unmount()
			-- os.remove(file_path)
		end, { noremap = true, silent = true })

		popup:map("n", "<leader><BS>", function()
			if config.event then
				popup:off(config.event)
			end
			popup:unmap("n", "<ESC>")
			popup:unmap("n", "<leader><BS>")
			popup:unmount()
			-- os.remove(file_path)
		end, { noremap = true, silent = true })

		if config.event then
			popup:on({ config.event }, function()
				popup:unmap("n", "<ESC>")
				popup:unmap("n", "<leader><BS>")
				popup:unmount()
				-- os.remove(file_path)
			end, { once = true })
		end
	end

	if new_lines then
		-- Get current lines in the popup buffer
		local current_lines = vim.api.nvim_buf_get_lines(config.popup.bufnr, 0, -1, false)
		-- Concatenate current lines with the new lines
		local updated_lines = vim.list_extend(current_lines, new_lines)
		-- local output_string = table.concat(output_table, "\n")
		-- vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, vim.split(output_string, "\n"))
		vim.api.nvim_buf_set_lines(config.popup.bufnr, 0, -1, false, updated_lines)
	else
		vim.api.nvim_buf_set_lines(config.popup.bufnr, 0, -1, false, { "Failed to read output" })
	end
end

-- Function to open a vertical split window and return the buffer number
---@return number
function M.open_vertical_split()
	vim.cmd("vsplit") -- Open a vertical split
	local bufnr = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
	vim.api.nvim_win_set_buf(0, bufnr) -- Set the new buffer to the current window (vertical split)
	return bufnr
end

-- Function to split a multiline string into individual lines
local function split_multiline_string(str)
	local lines = {}
	for line in str:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	return lines
end

-- Function to stream data to the buffer
---@param bufnr number
---@param data table
function M.stream_to_buffer(bufnr, data)
	-- Process each line to ensure no newlines are present
	local processed_data = {}
	for _, line in ipairs(data) do
    local clean_line = line:gsub("\027%[[%d;]*[ABCDEFGHJKSfminu]", "")
		for _, split_line in ipairs(split_multiline_string(clean_line)) do
			table.insert(processed_data, split_line)
		end
	end

	-- Get current lines in the popup buffer
	local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	-- Concatenate current lines with the new lines
	local updated_lines = vim.list_extend(current_lines, processed_data)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, updated_lines)
end

function M.activate_venv()
	local venv_path = vim.fn.getcwd() .. "/.venv"

	if vim.fn.isdirectory(venv_path) == 1 then
		-- Store old PATH to allow deactivation
		vim.env._OLD_VIRTUAL_PATH = vim.env.PATH

		-- Store old PYTHONHOME if set
		if vim.env.PYTHONHOME then
			vim.env._OLD_VIRTUAL_PYTHONHOME = vim.env.PYTHONHOME
			vim.env.PYTHONHOME = nil
		end

		-- Set VIRTUAL_ENV
		vim.env.VIRTUAL_ENV = venv_path

		-- Update PATH
		vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH

		-- Set prompt prefix (if you're using something that shows env vars in prompt)
		local venv_name = vim.fn.fnamemodify(venv_path, ":t")
		vim.env.VIRTUAL_ENV_PROMPT = "(" .. venv_name .. ") "
	end
end

function M.deactivate_venv()
	-- Restore old PATH
	if vim.env._OLD_VIRTUAL_PATH then
		vim.env.PATH = vim.env._OLD_VIRTUAL_PATH
		vim.env._OLD_VIRTUAL_PATH = nil
	end

	-- Restore old PYTHONHOME
	if vim.env._OLD_VIRTUAL_PYTHONHOME then
		vim.env.PYTHONHOME = vim.env._OLD_VIRTUAL_PYTHONHOME
		vim.env._OLD_VIRTUAL_PYTHONHOME = nil
	end

	-- Clear virtual env variables
	vim.env.VIRTUAL_ENV = nil
	vim.env.VIRTUAL_ENV_PROMPT = nil
end

return M
