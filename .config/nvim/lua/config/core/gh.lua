local utils = require("config.core.utils")
local snacks = require("snacks")

-- local actions = require("telescope.actions")
-- local action_state = require("telescope.actions.state")
-- local builtin = require("telescope.builtin")

local M = {}

---@param cb function
local function select_git_branch(cb)
	snacks.picker.git_branches({
		sort = {
			fields = {
				"current",
			},
		},
		confirm = function(picker)
			local item = picker:current()
			if not item then
				return
			end
			cb(item.branch)
			picker:close()
		end,
	})
end

-- local function select_git_branch_custom(cb)
--   -- Get git branches manually if needed
--   local handle = io.popen("git branch -a --format='%(refname:short)'")
--   if not handle then
--     vim.notify("Failed to get git branches", vim.log.levels.ERROR)
--     return
--   end
--
--   local branches = {}
--   for line in handle:lines() do
--     if line ~= "" and not line:match("HEAD") then
--       -- Clean up remote branch names
--       local branch = line:gsub("^%s*", ""):gsub("^origin/", "")
--       table.insert(branches, {
--         text = branch,
--         value = branch,
--       })
--     end
--   end
--   handle:close()
--
--   Snacks.picker.pick({
--     source = branches,
--     prompt = "Select Git Branch",
--     confirm = function(item)
--       cb(item.value)
--     end,
--     -- Optional: Add custom keymaps if needed
--     win = {
--       input = {
--         keys = {
--           ["<CR>"] = {
--             function(self)
--               local item = self:current()
--               if item then
--                 cb(item.value)
--                 self:close()
--               end
--             end,
--             mode = { "i", "n" }
--           }
--         }
--       }
--     }
--   })
-- end
-- local function select_git_branch(cb)
-- 	builtin.git_branches({
-- 		attach_mappings = function(prompt_bufnr, map)
-- 			local function select_branch()
-- 				local selection = action_state.get_selected_entry()
-- 				actions.close(prompt_bufnr)
--
-- 				cb(selection.value)
-- 			end
-- 			map("i", "<CR>", select_branch)
-- 			map("n", "<CR>", select_branch)
-- 			return true
-- 		end,
-- 	})
-- end

local function gh_exec(args)
	vim.notify("Creating Pull Request: " .. vim.inspect(args))
	local resp = vim.fn.system(args)

	local _, decoded_resp = pcall(function()
		return vim.json.decode(resp)
	end)

	if decoded_resp ~= nil then
		if vim.v.shell_error ~= 0 then
			if decoded_resp.errors then
				local details = decoded_resp.errors
				local message = decoded_resp.message or "No message provided"
				local doc_url = decoded_resp.documentation_url or "No documentation URL provided"
				local error_message =
					string.format("Error: %s\n\nDocumentation: %s\nDetails: %s\n", message, doc_url, details)
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
end

---@param args table
local function get_base_git_branch(args)
	local command = "gh repo view --json defaultBranchRef"
	local output = utils.execute_command(command)
	local ok, data = pcall(function()
		return vim.json.decode(output)
	end)
	assert(ok, data)

	if data == nil then
		error("Failed to get default branch ref")
	end

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

	vim.ui.input({ prompt = "Pull Request" }, function(input)
		if input == nil or input == "" then
			vim.notify("Please input a title")
			return
		end
		table.insert(args, "-f")
		table.insert(args, "title=" .. input)

		get_body_template(args)
	end)
end

return M
