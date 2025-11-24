vim.api.nvim_create_user_command("CleanAndRestartLsp", function()
	local current = vim.api.nvim_get_current_buf()

	-- Delete all buffers EXCEPT current
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end

	vim.defer_fn(function()
		vim.cmd("LspRestart")
	end, 200)
end, {})
