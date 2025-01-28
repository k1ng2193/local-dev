require("config.core.set")
require("config.core.remap")

vim.env.PYENV_VERSION = vim.fn.system("pyenv version"):match("(%S+)%s+%(.-%)")

vim.api.nvim_set_hl(0, "LineNr", { fg = "white" })

-- Function to detect and set Python path
local function set_python_path()
	-- Detect .venv in current or parent directories
	local venv_path = vim.fn.getcwd() .. "/.venv"

	if vim.fn.isdirectory(venv_path) == 1 then
		-- Find the specific Python version directory
		local site_packages = vim.fn.glob(venv_path .. "/lib/python3*/site-packages")

		if site_packages ~= "" then
			vim.env.PYTHONPATH = site_packages
		end
	end
end

-- Call the function when setting up LSP or on buffer enter
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.py" },
	callback = set_python_path,
})

set_python_path()
