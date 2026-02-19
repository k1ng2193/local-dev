local M = {}

local win_utils = require("core.win")

local uv = vim.uv
local api = vim.api

M.active_processes = {}

--- Given a string, convert 'slash' to 'inverted slash' if on windows, and vice versa on UNIX.
-- Then return the resulting string.
---@param path string
---@return string|nil, nil
function M.os_path(path)
  if path == nil then
    return nil
  end
  -- Get the platform-specific path separator
  local separator = package.config:sub(1, 1)
  return string.gsub(path, "[/\\]", separator)
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

-- Function to open a vertical split window and return the buffer number
---@return number
function M.open_vertical_split()
  vim.cmd("vsplit") -- Open a vertical split
  local bufnr = api.nvim_create_buf(false, true) -- Create a new empty buffer
  api.nvim_win_set_buf(0, bufnr) -- Set the new buffer to the current window (vertical split)
  return bufnr
end

-- Function to split a multiline string into individual lines
function M.split_multiline_string(str)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

-- Function to stream data to the buffer
---@param bufnr integer
---@param data table
function M.stream_to_buffer(bufnr, data)
  -- Process each line to ensure no newlines are present
  local processed_data = {}
  for _, line in ipairs(data) do
    local clean_line = line:gsub("\027%[[%d;]*[ABCDEFGHJKSfminu]", "")
    for _, split_line in ipairs(M.split_multiline_string(clean_line)) do
      table.insert(processed_data, split_line)
    end
  end

  -- Get current lines in the popup buffer
  local current_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- Concatenate current lines with the new lines
  local updated_lines = vim.list_extend(current_lines, processed_data)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, updated_lines)
end

-- Function find a file
---@param file_name string
---@param max_depth number | nil
---@param current_depth number | nil
---@param start_path string | nil
function M.find_path_for_file(file_name, max_depth, current_depth, start_path)
  if vim.fn.filereadable(start_path .. "/" .. file_name) == 1 then
    return start_path
  end

  max_depth = max_depth or 10
  current_depth = current_depth or 0
  start_path = start_path or vim.fn.getcwd()

  if current_depth > max_depth then
    return nil
  end

  local paths = vim.fn.globpath(start_path, "*", false, true)
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 then
      if vim.fn.filereadable(path .. "/" .. file_name) == 1 then
        return path
      end
      return M.find_path_for_file(file_name, max_depth, current_depth + 1, path)
    end
  end
end

---@param bufnr integer
---@param root_file string
function M.activate_venv(bufnr, root_file)
  local cwd = vim.fn.getcwd()
  local stop_dir = vim.fs.dirname(api.nvim_buf_get_name(bufnr))
  local root_path = vim.fs.find({ root_file }, { path = cwd, stop = stop_dir })
  if #root_path == 0 then
    vim.notify("No python virtual environment found")
    return
  end

  local venv_path = root_path[1]
  vim.notify(venv_path)
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

---@param bufnr integer
---@param on_dir function
---@param root_markers table
function M.find_lsp_root_dir(bufnr, on_dir, root_markers)
  local current_dir = vim.fs.dirname(api.nvim_buf_get_name(bufnr))
  local root_path =
    vim.fs.find(root_markers, { upward = true, path = current_dir, stop = vim.fs.dirname(vim.fn.getcwd()) })
  if root_path then
    on_dir(vim.fs.dirname(root_path[1]))
  end
end

---@class JobConfig
---@field cmd string
---@field args string[]
---@field cwd string?

---@param bufnr integer
---@param opts JobConfig
---@param on_success fun()?
---@return uv.uv_process_t
function M.async_job(bufnr, opts, on_success)
  local cmd_str = opts.cmd .. " " .. table.concat(opts.args, " ")
  vim.notify("Executing " .. cmd_str, vim.log.levels.INFO)

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  assert(stdout, "Command '" .. cmd_str .. "' failed: stdout pipe is nil")
  assert(stderr, "Command '" .. cmd_str .. "' failed: stderr pipe is nil")

  local handle
  handle = uv.spawn(opts.cmd, {
    args = opts.args,
    cwd = opts.cwd,
    stdio = { nil, stdout, stderr },
  }, function(code, signal)
    local signal_names = {
      [1] = "SIGHUP",
      [2] = "SIGINT",
      [3] = "SIGQUIT",
      [9] = "SIGKILL",
      [15] = "SIGTERM",
    }
    vim.schedule(function()
      stdout:read_stop()
      stderr:read_stop()
      stdout:close()
      stderr:close()

      M.active_processes[handle] = nil

      if signal ~= 0 then
        local signal_name = signal_names[signal] or ("signal " .. signal)
        vim.notify(string.format("Process terminated by %s (%d)", signal_name, signal), vim.log.levels.WARN)
      elseif code == 0 then
        vim.notify("Successfully executed " .. cmd_str, vim.log.levels.INFO)
        if on_success ~= nil then
          on_success()
        end
      else
        api.nvim_buf_set_lines(bufnr, -1, -1, false, {
          "",
          "--- Job failed with exit code: " .. code .. " ---",
        })
      end
    end)

    if not handle then
      vim.notify("Failed to spawn command: " .. cmd_str, vim.log.levels.ERROR)
      return
    end
  end)

  M.active_processes[handle] = true

  stdout:read_start(function(err, data)
    if data then
      vim.schedule(function()
        local lines = vim.split(data, "\n", { trimempty = true })
        api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
      end)
    end
  end)

  stderr:read_start(function(err, data)
    if data then
      vim.schedule(function()
        local lines = vim.split(data, "\n", { trimempty = true })
        api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
      end)
    end
  end)

  return handle
end

---@param proc uv.uv_process_t
function M.kill_gracefully(proc)
  if M.active_processes[proc] then
    proc:kill(15)

    vim.defer_fn(function()
      if M.active_processes[proc] and not proc:is_closing() then
        proc:kill(2)
        vim.defer_fn(function()
          if M.active_processes[proc] and not proc:is_closing() then
            proc:kill(9)
          end
        end, 2000)
      end
    end, 3000)
  end
end

---@class ExecuteOpts
---@field job JobConfig
---@field win WindowConfig?
---@field auto_close boolean?

---@param opts ExecuteOpts
---@param wrap boolean?
---@param on_success fun()?
---@return uv.uv_process_t
function M.execute_job(opts, wrap, on_success)
  assert(opts.job, "Missing job config in 'opts'")
  assert(opts.job.cmd, "Missing cmd in job config")
  assert(opts.job.args, "Missing args in job config")

  local bufnr = api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = opts.job.cmd
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buftype = "nofile"

  ---@type WindowConfig
  opts.win = vim.tbl_extend(
    "force",
    opts.win or {},
    { title = "Command: " .. opts.job.cmd .. " " .. table.concat(opts.job.args, " ") }
  )
  local win = win_utils.open_floating_window(bufnr, opts.win)

  vim.wo[win].wrap = wrap or false
  vim.wo[win].cursorline = true

  if opts.auto_close then
    local original_on_success = on_success

    on_success = function()
      if original_on_success then
        original_on_success()
      end

      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  end

  local proc = M.async_job(bufnr, opts.job, on_success)

  vim.keymap.set("n", "q", ":close<CR>", { buffer = bufnr, silent = true })
  vim.keymap.set("n", "<Esc>", ":close<CR>", { buffer = bufnr, silent = true })
  vim.keymap.set("n", "<C-c>", function()
    M.kill_gracefully(proc)
  end, { buffer = bufnr, silent = true })

  return proc
end

return M
