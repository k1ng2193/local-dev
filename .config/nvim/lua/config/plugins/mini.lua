return {
	"echasnovski/mini.nvim",
	version = "*",
	config = function()
		local mini_files = require("mini.files")
		mini_files.setup({
			options = {
				-- Whether to delete permanently or move into module-specific trash
				permanent_delete = false,
			},
		})

		vim.keymap.set("n", "<leader>t", function()
			mini_files.open()
		end, { noremap = true, silent = true, desc = "Open File System" })

		local function get_relative_path()
			local entry = mini_files.get_fs_entry()
			if not entry then
				return nil
			end

			-- Get current working directory
			local home = os.getenv("HOME")

			-- Remove the current working directory from the full path
			local relative_path = "~/" .. entry.path:sub(#home + 2)

			return relative_path
		end

		-- Mapping to get and print/copy relative path
		vim.keymap.set("n", "<leader>rp", function()
			local relative_path = get_relative_path()
			if relative_path then
				vim.notify("Copied Relative Path: " .. relative_path)

				vim.fn.setreg("+", relative_path)
			end
		end, { desc = "Copy Relative Path" })

		local map_split = function(buf_id, lhs, direction)
			local rhs = function()
				-- Make new window and set it as target
				local cur_target = mini_files.get_explorer_state().target_window
				local new_target = vim.api.nvim_win_call(cur_target, function()
					vim.cmd(direction .. " split")
					return vim.api.nvim_get_current_win()
				end)

				mini_files.set_target_window(new_target)

        mini_files.go_in({ close_on_file = true })
			end

			-- Adding `desc` will result into `show_help` entries
			local desc = "Split " .. direction
			vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferCreate",
			callback = function(args)
				local buf_id = args.data.buf_id
				-- Tweak keys to your liking
				map_split(buf_id, "<C-s>", "belowright horizontal")
				map_split(buf_id, "<C-v>", "belowright vertical")
			end,
		})
	end,
}
