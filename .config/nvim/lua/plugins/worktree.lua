local title = "Git Worktrees"
local commit_pat = ("[a-z0-9]+")

local force_next_deletion = false

---@param ... (string|string[]|nil)
local function git_args(...)
	local ret = { "-c", "core.quotepath=false" } ---@type string[]
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		vim.list_extend(ret, type(arg) == "table" and arg or { arg })
	end
	return ret
end

local function toggle_forced_deletion(picker)
	force_next_deletion = not force_next_deletion

	local status = force_next_deletion and " [FORCE DELETE]" or ""
	picker.title = title .. status
	picker:update_titles()

	vim.cmd.redraw()
end

local function delete_success_handler()
	force_next_deletion = false
end

local function delete_failure_handler()
	vim.notify("Deletion failed, use <C-f> to force the next deletion", vim.log.levels.WARN)
end

local function ask_to_confirm_deletion(forcing)
	if forcing then
		return vim.fn.input("Force deletion of worktree? [y/n]: ")
	end

	return vim.fn.input("Delete worktree? [y/n]: ")
end

local function confirm_deletion(forcing)
	local confirmed = ask_to_confirm_deletion(forcing)

	if string.sub(string.lower(confirmed), 0, 1) == "y" then
		return true
	end

	vim.notify("Didn't delete worktree")
	return false
end

local function git_worktrees(opts, ctx)
	local uv = vim.uv or vim.loop
	local snacks = require("snacks")
	local args = git_args(opts.args, "--no-pager", "worktree", "list", "-v")

	local cwd = vim.fs.normalize(opts and opts.cwd or uv.cwd() or ".") or nil
	cwd = snacks.git.get_root(cwd)
	local pattern = "^(.-)%s+(" .. commit_pat .. ")%s+%[([^%]]+)%].*$"
	-- local pattern = "^([^%s]+)%s+(" .. commit_pat .. ")%s+%[([^%]]+)%].*$"

	return require("snacks.picker.source.proc").proc({
		opts,
		{
			cwd = cwd,
			cmd = "git",
			args = args,
			transform = function(item)
				item.cwd = cwd
				if item.text:match("%(bare%)") then
					return false
				end
				local path, commit, branch = item.text:match(pattern)
				if path then
					item.current = path == cwd
					item.path = path
					item.branch = branch
					item.commit = commit
					return
				end

				snacks.notify.warn("failed to parse branch: " .. item.text)
				return false
			end,
		},
	}, ctx)
end

local function git_commit(item, picker)
	local snacks = require("snacks")

	local a = snacks.picker.util.align
	local ret = {}
	ret[#ret + 1] = { picker.opts.icons.git.commit, "SnacksPickerGitCommit" }
	ret[#ret + 1] = { a(item.commit, 8, { truncate = true }), "SnacksPickerGitCommit" }
	snacks.picker.highlight.markdown(ret)

	return ret
end

local function git_worktree(item, picker)
	local snacks = require("snacks")

	local a = snacks.picker.util.align
	local ret = {}
	if item.current then
		ret[#ret + 1] = { a("", 2), "SnacksPickerGitBranchCurrent" }
	else
		ret[#ret + 1] = { a("", 2) }
	end
	ret[#ret + 1] = { a(item.branch, 70, { truncate = true }), "SnacksPickerGitBranch" }
	ret[#ret + 1] = { " " }

	local offset = snacks.picker.highlight.offset(ret)
	local commit = git_commit(item, picker)
	snacks.picker.highlight.fix_offset(commit, offset)
	vim.list_extend(ret, commit)

	return ret
end

local function create_worktree(picker)
	local input = picker.input.filter.pattern
	local item = picker:current()
	if not item and (input == nil or input == "") then
		return
	end

	local branch = item and item.branch or input

	vim.ui.input({
		prompt = "Path to subtree > ",
	}, function(path)
		if path == "" then
			path = branch
		end
		require("git-worktree").create_worktree(path, branch)
		picker:close()
	end)
end

local function git_worktree_switch(picker)
	local item = picker:current()
	if not item then
		return
	end

	if item.path then
		require("git-worktree").switch_worktree(item.path)
		picker:close()
	end
end

local function git_worktree_delete(picker)
	local item = picker:current()
	if not item then
		return
	end

	if item.current then
		vim.notify("Cannot delete current worktree", vim.log.levels.ERROR)
		return
	end

	if not confirm_deletion() then
		return
	end

	if item.path ~= nil then
		require("git-worktree").delete_worktree(item.path, force_next_deletion, {
			on_failure = delete_failure_handler,
			on_success = delete_success_handler,
		})
		picker:close()
	end
end

return {
	"ThePrimeagen/git-worktree.nvim",
	-- dependencies = { 'nvim-telescope/telescope.nvim' },
	dependencies = { "folke/snacks.nvim" },
	event = { "BufEnter", "BufNewFile" },
	specs = {
		"folke/snacks.nvim",
		opts = function(_, opts)
			return vim.tbl_deep_extend("force", opts or {}, {
				picker = {
					sources = {
						create_git_worktree = {
							all = true,
							finder = "git_branches",
							format = "git_branch",
							preview = "git_log",
							confirm = create_worktree,
							matcher = { fuzzy = false },
						},
						git_worktrees = {
							title = title,
							finder = git_worktrees,
							format = git_worktree,
							layout = { preview = false },
							sort = {
								fields = {
									"current",
								},
							},
							confirm = git_worktree_switch,
							matcher = { fuzzy = false },
							actions = {
								git_worktree_delete = git_worktree_delete,
								git_worktree_force = toggle_forced_deletion,
							},
							win = {
								input = {
									keys = {
										["<c-d>"] = { "git_worktree_delete", mode = { "n", "i" } },
										["<c-f>"] = { "git_worktree_force", mode = { "n", "i" } },
									},
								},
							},
							on_show = function(picker)
								for i, item in ipairs(picker:items()) do
									if item.current then
										picker.list:view(i)
										require("snacks").picker.actions.list_scroll_center(picker)
										break
									end
								end
							end,
						},
					},
				},
			})
		end,
	},
	config = function()
		local worktree = require("git-worktree")
		local snacks = require("snacks")
		local utils = require("core.utils")

		worktree.setup({
			change_directory_command = "cd",
			update_on_change = true,
			update_on_change_command = "e .",
			clearjumps_on_change = true,
			autopush = false,
		})

		worktree.on_tree_change(function(op, metadata)
			if op == worktree.Operations.Create then
				print("Created " .. metadata.branch .. " branch tracking " .. metadata.upstream)
			end

			if op == worktree.Operations.Switch then
				print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
				utils.deactivate_venv()
			end
		end)

		-- require("telescope").load_extension("git_worktree")
		--
		-- vim.keymap.set(
		-- 	"n",
		-- 	"<leader>fw",
		-- 	":lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
		-- 	{ noremap = true, silent = true, desc = "Switch and Delete Git Worktree" }
		-- )
		-- vim.keymap.set(
		-- 	"n",
		-- 	"<leader>wc",
		-- 	":lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
		-- 	{ noremap = true, silent = true, desc = "Create Git Worktree" }

		vim.keymap.set("n", "<leader>fw", function()
			snacks.picker.git_worktrees()
		end, { desc = "Search Git Worktree" })
		vim.keymap.set("n", "<leader>wc", function()
			snacks.picker.create_git_worktree()
		end, { desc = "Create Git Worktree" })
	end,
}
