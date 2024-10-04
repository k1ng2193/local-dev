local utils = require("config.core.utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local builtin = require("telescope.builtin")

local M = {}

---@param cb function
local function select_git_branch(cb)
	builtin.git_branches({
		attach_mappings = function(prompt_bufnr, map)
			local function select_branch()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)

				cb(selection.value)
			end
			map("i", "<CR>", select_branch)
			map("n", "<CR>", select_branch)
			return true
		end,
	})
end

local function gh_exec(args)
	vim.notify("Creating Pull Request: " .. vim.inspect(args))
	local resp = vim.fn.system(args)

  local _, decoded_resp = pcall(function()
    return vim.json.decode(resp)
  end)

	if vim.v.shell_error ~= 0 then
    if decoded_resp.errors then
      local details = decoded_resp.errors
      local message = decoded_resp.message or "No message provided"
      local doc_url = decoded_resp.documentation_url or "No documentation URL provided"
      local error_message = string.format("Error: %s\n\nDocumentation: %s\nDetails: %s\n", message, doc_url, details)
      vim.notify(error_message, 4)
    else
      vim.notify("Error: " .. resp, 4)
    end
	else
    local pr_url = decoded_resp.html_url
		vim.notify("Successfully created pull request: " .. pr_url)
    utils.open_url(pr_url)
	end
end

---@param args table
local function get_base_git_branch(args)
	local command = "gh repo view --json defaultBranchRef"
	local output = utils.execute_command(command)
	local ok, data = pcall(function()
		return vim.json.decode(output)
	end)
	assert(ok, data)

	local base = data.defaultBranchRef.name
	if base == "" or base == nil then
		error("Failed to get the base branch")
	end

	table.insert(args, "-f")
	table.insert(args, "base=" .. base)

	gh_exec(args)
end

---@param args table
local function get_head_git_branch(args)
	select_git_branch(function(head)
		if head == "" or head == nil then
			error("Failed to get the head branch")
		end

		vim.notify("Selected head branch: " .. head)
		table.insert(args, "-f")
		table.insert(args, "head=" .. head)

		get_base_git_branch(args)
	end)
end

---@param args table
local function get_body_template(args)
	local local_cwd = vim.fn.getcwd()
	local template = local_cwd .. "/pull_request_template.md"
	local stat = vim.loop.fs_stat(template)

	if stat and stat.type == "file" then
		local body = utils.read_file(template)

		if body then
			table.insert(args, "-f")
			table.insert(args, "body=" .. body)
		end
	end

	get_head_git_branch(args)
end

function M.create_pr()
	local args = { "gh", "api", "--method", "POST", "repos/{owner}/{repo}/pulls" }

	local title_input_config = {
		position = "50%",
		size = {
			width = 75,
		},
		border = {
			style = "single",
			text = {
				top = "[Pull Request Title]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}
	local title_input_prompt = {
		prompt = "> ",
		on_close = function()
			vim.notify("Please input a title")
		end,
		on_submit = function(value)
			table.insert(args, "-f")
			table.insert(args, "title=" .. value)

			get_body_template(args)
		end,
	}
	utils.mount_input(title_input_config, title_input_prompt)
end

return M
