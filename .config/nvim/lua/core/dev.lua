local M = {}

local utils = require("core.utils")

---@param cb function | nil
function M.sso(cb)
	local profiles = vim.fn.system("grep '^\\[profile' ~/.aws/config | cut -d ' ' -f 2 | tr -d '[]' | sort")
	local lines = utils.split_multiline_string(profiles)

	vim.ui.select(lines, {
		prompt = "AWS Profile",
	}, function(choice)
		if choice == nil then
			return
		end

		vim.env.AWS_PROFILE = choice
		local result = vim.fn.system("aws sso login")
		vim.notify(result)
		if cb then
			cb()
		end
	end)
end

function M.artifact()
	local cmd =
		"aws codeartifact get-authorization-token --domain vareto --domain-owner 544138963155 --query authorizationToken --output text"
	local token_list = vim.fn.systemlist(cmd)
	local token = token_list[1] -- Extract the first line of output
	if token_list and token_list[1] ~= "" then
		local pip_url = "'https://aws:"
			.. token
			.. "@vareto-544138963155.d.codeartifact.us-west-2.amazonaws.com/pypi/vareto-python/simple'"
    local config_cmd = "pip3 config set global.index-url " .. pip_url
		local result = vim.fn.system(config_cmd)
		print(result) -- Print the result of the second command
		vim.fn.system("cp ~/.config/pip/pip.conf pip.conf")
		vim.env.PIP_INDEX_URL = pip_url
		-- vim.env.UV_INDEX_URL = pip_url
	else
		error("Failed to get CodeArtifact token.")
	end
end

function M.docker_login()
	local cmd =
		"aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 137149808471.dkr.ecr.us-west-2.amazonaws.com"
	local result = vim.fn.system(cmd)
	vim.notify(result)
end

return M
