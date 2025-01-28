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
	end,
}
