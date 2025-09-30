local M = {}
local utils = require("core.utils")
local dev = require("core.dev")

local container
local port
local name
local network
local local_cwd
local localhost = "127.0.0.1"
local default_port = { port = "5678" }

---@param option string
---@param cb function | nil
local function run_docker_compose(option, cb)
	local overseer = require("overseer")
	local final_message = "--task finished--"
	local task = overseer.new_task({
		name = "- Docker Compose Interpreter",
		strategy = {
			"orchestrator",
			tasks = {
				{
					"shell",
					name = "- Run docker compose → " .. option,
					cmd = option -- run
						.. " && echo "
						.. option -- echo
						.. " && echo '"
						.. final_message
						.. "'",
				},
			},
		},
	})
	task:start()

	if type(cb) == "function" then
		cb()
	end
end

local function load_dap()
	local ok, dap = pcall(require, "dap")
	assert(ok, "nvim-dap is required to use dap-python")
	return dap
end

local function get_nodes(query_text, predicate)
	local end_row = vim.api.nvim_win_get_cursor(0)[1]
	local ft = vim.api.nvim_buf_get_option(0, "filetype")
	assert(ft == "python", "test_method of dap-python only works for python files, not " .. ft)
	local query = (
		vim.treesitter.query.parse and vim.treesitter.query.parse(ft, query_text)
		or vim.treesitter.parse_query(ft, query_text)
	)
	assert(query, "Could not parse treesitter query. Cannot find test")
	local parser = vim.treesitter.get_parser(0)
	assert(parser, "Could not find treesitter language parser")
	local root = (parser:parse()[1]):root()
	local nodes = {}
	for _, node in query:iter_captures(root, 0, 0, end_row) do
		if predicate(node) then
			table.insert(nodes, node)
		end
	end
	return nodes
end

local function get_node_text(node)
	local row1, col1, row2, col2 = node:range()
	if row1 == row2 then
		row2 = row2 + 1
	end
	local lines = vim.api.nvim_buf_get_lines(0, row1, row2, true)
	if #lines == 1 then
		return (lines[1]):sub(col1 + 1, col2)
	end
	return table.concat(lines, "\n")
end

local function get_function_nodes()
	local query_text = [[
            (function_definition
              name: (identifier) @name) @definition.function
          ]]
	return get_nodes(query_text, function(node)
		return node:type() == "identifier"
	end)
end

local function closest_above_cursor(nodes)
	local result
	for _, node in pairs(nodes) do
		if not result then
			result = node
		else
			local node_row1, _, _, _ = node:range()
			local result_row1, _, _, _ = result:range()
			if node_row1 > result_row1 then
				result = node
			end
		end
	end
	return result
end

local function get_parent_classname(node)
	local parent = node:parent()
	while parent do
		local type = parent:type()
		if type == "class_definition" then
			for child in parent:iter_children() do
				if child:type() == "identifier" then
					return get_node_text(child)
				end
			end
		end
		parent = parent:parent()
	end
end

local function prune_nil(items)
	return vim.tbl_filter(function(x)
		return x
	end, items)
end

local function get_test_path(classname, methodname)
	local path = vim.fn.expand("%:p:.")
	local project_root = utils.find_path_for_file("pyproject.toml", 1, 0, ".")
	if project_root then
		if not project_root:match("/$") then
			project_root = project_root .. "/"
		end
		if project_root:sub(1, 2) == "./" then
			project_root = project_root:sub(3)
		end
	end

	-- Check if the path starts with the project root
	if path:sub(1, #project_root) == project_root then
		path = path:sub(#project_root + 1)
	end

	local test_path = table.concat(prune_nil({ path, classname, methodname }), "::")

	return test_path
end

---@param session_port integer
---@return integer|nil
local function disconnect_old_session(session_port)
	local sessions = require("dap").sessions()

	for _, session in pairs(sessions) do
		local adapter = session.adapter

		if adapter and adapter.port == session_port then
			vim.notify("Disconnecting DAP session at port: " .. port)
			load_dap().disconnect({ session.id })
		end
	end
end

-- Function to execute a Docker command and capture its output
---@param args table
---@param callback function
local function execute_remote_docker_command(args, callback)
	local uv = vim.uv
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	local output = {}

	local handle, pid
	handle, pid = uv.spawn("docker", {
		args = args,
		stdio = { nil, stdout, stderr },
	}, function(code, signal)
		stdout:read_stop()
		stderr:read_stop()
		stdout:close()
		stderr:close()
		if handle then
			handle:close()
		end

		vim.schedule(function()
			callback(code, signal, output)
		end)
	end)

	if not handle then
		vim.notify("Failed to spawn process", 4)
		return
	end

	stdout:read_start(function(err, data)
		assert(not err, err)
		if data then
			table.insert(output, data)
		end
	end)

	stderr:read_start(function(err, data)
		assert(not err, err)
		if data then
			table.insert(output, data)
		end
	end)
end

---@param docker_command string
---@param cb function | nil
local function execute_docker_command(docker_command, cb)
	local bufnr = utils.open_vertical_split()

	local stderr_message
	local stdout_msg

	vim.fn.jobstart(docker_command, {
		on_stdout = function(_, data, _)
			-- Handle stdout data
			if type(data) == "table" then
				stdout_msg = table.concat(data, "\n")
			else
				-- If data is not a table, assume it's a single chunk
				stdout_msg = data
			end
			if stdout_msg ~= "" then
				utils.stream_to_buffer(bufnr, data)
			end
		end,
		on_stderr = function(_, data, _)
			-- Handle stderr data
			if type(data) == "table" then
				-- Concatenate chunks of stderr data
				stderr_message = table.concat(data, "\n")
			else
				-- If data is not a table, assume it's a single chunk
				stderr_message = data
			end
		end,
		on_exit = function(_, exit_code, _)
			if exit_code == 0 then
				vim.notify("Successfully executed docker command: " .. docker_command)
				if type(cb) == "function" then
					cb()
				end
			else
				vim.env.AWS_PROFILE = nil
				vim.notify("Failed to execute docker command: " .. docker_command, 4)
				error(stderr_message)
			end

			local current_lines = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
			if current_lines == "" then
				vim.cmd("bdelete " .. bufnr)
			end
		end,

		stdout_buffered = false, -- Enable stdout buffering
		stderr_buffered = true, -- Enable stderr buffering
	})
end

local function DockerCoroutine(docker_command)
	return coroutine.create(function()
		local job_id = vim.fn.jobstart(docker_command)
		-- Wait for the job to complete
		vim.fn.jobwait(job_id)
	end)
end

---@param opts table
---@param cb function
local function get_docker_services(opts, cb)
	local_cwd = vim.fn.getcwd()
	local docker_compose_filepath = local_cwd .. "/docker-compose.yml"
	local stat = vim.uv.fs_stat(docker_compose_filepath)
	if not stat or stat.type ~= "file" then
		error("docker-compose.yml not found at " .. docker_compose_filepath)
	end

	if not container or opts.action == "start" or opts.action == "build" or opts.action == "pytest" then
		local services = vim.fn.system("yq eval '.services | keys | .[]' " .. docker_compose_filepath)
		local lines = utils.split_multiline_string(services)
		local title = opts.action:gsub("^%l", string.upper)

		vim.ui.select(lines, {
			prompt = "Docker Services " .. title,
		}, function(choice)
			if choice == nil then
				return
			end

			container = choice
			cb()
		end)
	end
end

local function get_docker_containers(cb)
	local containers = vim.fn.system("docker ps --format '{{.Names}}'")
	local lines = utils.split_multiline_string(containers)

	vim.ui.select(lines, {
		prompt = "Docker Containers",
	}, function(choice)
		if choice == nil then
			return
		end

		cb(choice)
	end)
end

local function get_host(cb)
	vim.ui.input({ prompt = "Host Address", default = localhost }, function(input)
		if input == nil or input == "" then
			vim.notify("Please input a host address")
		end
		cb(input)
	end)
end

---@param local_port string | nil
local function get_port_and_attach(local_port)
	local input_port
	if local_port == nil then
		input_port = default_port.port
	else
		input_port = local_port
	end

	vim.ui.select({ "Yes", "No" }, { prompt = "Attach Debugger?" }, function(choice)
		if choice == "Yes" then
			vim.ui.input({ prompt = "Port", default = input_port }, function(input)
				if input == nil or input == "" then
					vim.notify("Please input a port")
				end
				port = tonumber(input)
				vim.notify("Attempting to attach to container at port: " .. port)
				if type(port) == "integer" then
					disconnect_old_session(port)
				end

				vim.defer_fn(function()
					M.attach_session({ host = localhost })
				end, 5000)
			end)
		end
	end)
end

function M.remove_network()
	local net = vim.fn.system("docker network ls")
	local lines = utils.split_multiline_string(net)

	vim.ui.select(lines, { prompt = "Remove Docker Network" }, function(choice)
		if choice == nil then
			return
		end

		vim.notify("Removing " .. choice)
		local docker_command = "docker network rm " .. choice
		local ok, result = pcall(execute_docker_command, docker_command)
		assert(ok, result)
	end)
end

-- Function to check if all containers are up and running
---@param message string
---@param up boolean
---@param delay integer
---@param on_complete function | nil
local function check_containers(message, up, delay, on_complete)
	local running_cmd = "docker compose ps --services --filter 'status=running' 2>/dev/null"
	local exited_cmd = "docker compose ps --services --filter 'status=exited' 2>/dev/null"

	local running = vim.fn.system(running_cmd)
	local exited = vim.fn.system(exited_cmd)
	running = running:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
	exited = exited:gsub("^%s*(.-)%s*$", "%1")

	local check_complete = false

	if not up then -- Checking for shutdown
		if running == "" then
			vim.notify("All containers have been shut down")
			container = nil
			check_complete = true

			if ShutDownTimer and not ShutDownTimer:is_closing() then
				ShutDownTimer:close()
				ShutDownTimer = nil
			end
		end
	else -- Checking for startup
		-- Split the result into lines and check for your container
		local services = {}
		for line in running:gmatch("[^\r\n]+") do
			if line:gsub("^%s*(.-)%s*$", "%1") ~= "" then -- ignore empty lines
				table.insert(services, line)
			end
		end

		for _, service in ipairs(services) do
			if service == container then
				vim.notify("All containers are up and running.")
				check_complete = true
				if StartUpTimer and not StartUpTimer:is_closing() then
					StartUpTimer:close()
					StartUpTimer = nil
				end
				break
			end
		end
	end

	if not check_complete then
		vim.notify(message)
		vim.defer_fn(function()
			check_containers(message, up, delay, on_complete)
		end, delay)
	elseif on_complete then
		on_complete()
	end
end
-- 	if running == "" or running == "nil" then
-- 		if up then
-- 			vim.notify("No containers are running", 4)
-- 			if StartUpTimer and not StartUpTimer:is_closing() then
-- 				StartUpTimer:close()
-- 			end
-- 		else
-- 			vim.notify("All containers have been shut down")
-- 			container = nil
--
-- 			-- vim.defer_fn(function()
-- 			-- remove_docker_network()
-- 			-- end, 30000)
--
-- 			if ShutDownTimer and not ShutDownTimer:is_closing() then
-- 				ShutDownTimer:close()
-- 			end
-- 		end
--
-- 		check_complete = true
-- 	end
--
-- 	if up then
-- 		-- Split the result into lines
-- 		local lines = {}
-- 		for running_line in running:gmatch("[^\r\n]+") do
-- 			table.insert(lines, running_line)
-- 		end
-- 		for exited_line in exited:gmatch("[^\r\n]+") do
-- 			table.insert(lines, exited_line)
-- 		end
--
-- 		for _, line in ipairs(lines) do
-- 			if line == container then
-- 				vim.notify("All containers are up and running.")
-- 				check_complete = true
--
-- 				if StartUpTimer and not StartUpTimer:is_closing() then
-- 					StartUpTimer:close()
-- 				end
-- 			end
-- 		end
-- 	end
--
-- 	if not check_complete then
-- 		vim.notify(message)
--
-- 		-- Reschedule the function to run again after a delay
-- 		vim.defer_fn(function()
-- 			check_containers(message, up, delay, on_complete)
-- 		end, delay)
-- 	elseif on_complete ~= nil then
-- 		on_complete()
-- 	end
-- end

-- Function to check if an individual container is running
---@param local_container string
---@param delay integer
---@param cb function
local function check_container(local_container, delay, cb)
	local result = vim.fn.system("docker ps --filter 'name=" .. local_container .. "' --format '{{.Names}}'")

	if result == "" or result == nil or local_container == nil then
		vim.notify("The " .. local_container .. " container shutdown successfully!")
		if local_container == container then
			container = nil
		end
		if KillTimer and not KillTimer:is_closing() then
			KillTimer:close()
		end
	else
		vim.notify("The " .. local_container .. " is still shutting down")

		-- Reschedule the function to run again after a delay
		vim.defer_fn(function()
			cb(local_container, delay, check_container)
		end, delay)
	end
end

---@param opts table
function M.run_pytest(opts)
	-- local dap = load_dap()
	name = "Data API Pytest"

	get_docker_services({ action = "pytest" }, function()
		-- vim.notify("Pytest listening at port: " .. port)
		local class = nil
		local function_name = nil
		local args = { "compose", "exec", container, "pytest" }

		if opts.type ~= "all" then
			if opts.type == "function" then
				local function_node = closest_above_cursor(get_function_nodes())
				if not function_node then
					vim.notify("No suitable test method found")
					return
				end
				class = get_parent_classname(function_node)
				function_name = get_node_text(function_node)
			end
			local test_path = get_test_path(class, function_name)
			vim.notify("Running Pytest for " .. test_path)
			table.insert(args, test_path)
		end

		execute_remote_docker_command(args, function(code, signal, output)
			vim.notify("Finished Pytest Process with code " .. code .. " and signal " .. signal)
			local bufnr = utils.open_vertical_split()
			utils.stream_to_buffer(bufnr, output)
		end)

		get_port_and_attach("6000")
	end)
end

---@param opts table | nil
---@param cb function | nil
local function docker_network_input(opts, cb)
	vim.ui.input({ prompt = "Docker Network" }, function(input)
		if input == nil or input == "" then
			vim.notify("Please input a docker network")
		end
		network = input
		local result = vim.fn.system("docker network ls --filter 'name=" .. network .. "' --format '{{.Name}}'")

		if result == "" then
			local resp = vim.fn.system("docker network create --driver bridge " .. network)
			vim.notify("The " .. network .. " docker network was created: " .. resp)
		else
			vim.notify("The " .. network .. " docker network already exists.")
		end
		if opts and opts.action == "start" and type(cb) == "function" then
			get_docker_services(opts, cb)
		end
	end)
end

---@param opts table | nil
---@param cb function | nil
local function create_docker_network(opts, cb)
	if network then
		local network_check = vim.fn.system("docker network ls --filter 'name=" .. network .. "' --format '{{.Name}}'")
		if network_check == "" then
			docker_network_input(opts, cb)
		elseif opts and opts.action == "start" and type(cb) == "function" then
			get_docker_services(opts, cb)
		end
	else
		docker_network_input(opts, cb)
	end
end

---@param opts table | nil
---@param cb function | nil
function M.get_docker_dependencies(opts, cb)
	local_cwd = vim.fn.getcwd()
	local pip_filepath = local_cwd .. "/pip.conf"
	local stat = vim.uv.fs_stat(pip_filepath)

	local callback = function()
		local artifact_ok, artifact_result = pcall(dev.artifact)
		if not artifact_ok then
			vim.env.AWS_PROFILE = nil
		end
		assert(artifact_ok, artifact_result)

		dev.docker_login()

		-- create_docker_network(opts, cb)
	end

	if not stat or stat.type ~= "file" or not vim.env.AWS_PROFILE then
		dev.sso(callback)
	-- else
	-- 	create_docker_network(opts, cb)
	end
end

function M.show_containers()
	local containers = vim.fn.system("docker ps")

	vim.notify(containers)
end

function M.list_image()
	local images = vim.fn.system("docker image ls")

	vim.notify(images)
end

function M.list_network()
	local net = vim.fn.system("docker network ls")

	vim.notify(net)
end

function M.list_volume()
	local vol = vim.fn.system("docker volume ls")

	vim.notify(vol)
end

function M.prune_build_cache()
	local builder = vim.fn.system("docker builder prune -f")

	vim.notify(builder)
end

function M.prune_image()
	local image = vim.fn.system("docker image prune -f")

	vim.notify(image)
end

function M.prune_network()
	local net = vim.fn.system("docker network prune -f")

	vim.notify(net)
end

function M.prune_volume()
	local volume = vim.fn.system("docker volume prune -f")

	vim.notify(volume)
end

function M.prune_system()
	local system = vim.fn.system("docker system prune -af")

	vim.notify(system)
end

function M.prune_container()
	local system = vim.fn.system("docker container prune -f")

	vim.notify(system)
end

function M.build_containers()
	get_docker_services({ action = "build" }, function()
		vim.ui.select({ "Yes", "No" }, { prompt = "Build With Cache?" }, function(choice)
			local docker_command = string.format("docker compose build " .. container)
			if choice == "No" then
				docker_command = string.format(docker_command .. " --no-cache")
			end
			run_docker_compose(docker_command)
		end)
	end)
end

---@param attach boolean
function M.start_containers(attach)
	if ShutDownTimer and not ShutDownTimer:is_closing() then
		ShutDownTimer:close()
	end

	name = "Data API"

	get_docker_services({ action = "start" }, function()
		load_dap().defaults.python.exception_breakpoints = { "default" }
		local docker_command = string.format("docker compose up " .. container)
		run_docker_compose(docker_command, function()
			StartUpTimer = vim.defer_fn(function()
				-- Terminate the process if it takes longer than 5 minutes
				vim.notify("Containers are taking too long to start. Please check the container statuses manually.")
			end, 60000) -- 60000 milliseconds = 1 minutes

			vim.notify("Checking container statuses...")

			local on_complete
			if attach then
				on_complete = get_port_and_attach
			end

			local message = "The " .. container .. " container is still booting up"
			-- Schedule the asynchronous function to be executed asynchronously in the next event loop iteration
			vim.defer_fn(function()
				check_containers(message, true, 15000, on_complete)
			end, 10000)
		end)
		-- assert(ok, result)

		-- if container == "shared_payload_load_data" then
		--     container = "shared_payload_data_api"
		-- end

		-- execute_docker_command(docker_command, function()
		-- 	vim.notify("Data API listening at port: " .. port)
		-- 	StartUpTimer = vim.defer_fn(function()
		-- 		-- Terminate the process if it takes longer than 5 minutes
		-- 		vim.notify("Containers are taking too long to start. Please check the container statuses manually.")
		-- 	end, 300000) -- 300000 milliseconds = 5 minutes
		--
		-- 	vim.notify("Checking container statuses...")
		--
		-- 	local message = "The " .. container .. " container is still booting up"
		-- 	-- Schedule the asynchronous function to be executed asynchronously in the next event loop iteration
		-- 	vim.defer_fn(function()
		-- 		check_containers(message, true, 15000)
		-- 	end, 10000)
		-- end)
	end)
	-- end)
end

function M.remove_container()
	get_docker_containers(function(local_container)
		local docker_command = string.format("docker rm " .. local_container)
		vim.notify("Removing the " .. local_container .. " container")
		local docker_coroutine = DockerCoroutine(docker_command)
		coroutine.resume(docker_coroutine)
	end)
end

function M.kill_container()
	if StartUpTimer and not StartUpTimer:is_closing() then
		StartUpTimer:close()
	end

	get_docker_containers(function(local_container)
		local docker_command = string.format("docker kill " .. local_container)
		vim.notify("Shutting down " .. local_container .. " container")
		local docker_coroutine = DockerCoroutine(docker_command)
		coroutine.resume(docker_coroutine)

		KillTimer = vim.defer_fn(function()
			-- Terminate the process if it takes longer than 5 minutes
			vim.notify(
				"The "
					.. local_container
					.. " container is taking too long to shutdown. Please check the container statuses manually."
			)
		end, 15000) -- milliseconds

		vim.notify("Checking container status...")

		-- Schedule the asynchronous function to be executed asynchronously in the next event loop iteration
		vim.defer_fn(function()
			check_container(local_container, 10000, check_container)
		end, 5000)
	end)
end

function M.stop_containers()
	if StartUpTimer and not StartUpTimer:is_closing() then
		StartUpTimer:close()
	end

	vim.ui.select({ "Yes", "No" }, { prompt = "Remove Volumes?" }, function(choice)
		local docker_command = string.format("docker compose --profile '*' down --remove-orphans")
		if choice == "Yes" then
			docker_command = string.format(docker_command .. " -v")
		end
		vim.notify("Shutting down all docker containers")
		local docker_coroutine = DockerCoroutine(docker_command)
		coroutine.resume(docker_coroutine)
	end)

	ShutDownTimer = vim.defer_fn(function()
		-- Terminate the process if it takes longer than 5 minutes
		vim.notify("Containers are taking too long to shutdown. Please check the container statuses manually.")
	end, 10000) -- milliseconds

	vim.notify("Checking container statuses...")

	local message = "Containers are still shutting down"
	-- Schedule the asynchronous function to be executed asynchronously in the next event loop iteration
	vim.defer_fn(function()
		check_containers(message, false, 3000)
	end, 1000)
end

function M.remove_image()
	local images = vim.fn.system("docker image ls --format '{{.Repository}}'")
	local lines = utils.split_multiline_string(images)
	vim.ui.select(lines, {
		prompt = "Remove Docker Image",
	}, function(choice)
		if choice == nil then
			return
		end

		vim.notify("Removing " .. choice)
		local docker_command = string.format("docker image rm " .. choice)
		local ok, result = pcall(execute_docker_command, docker_command)
		assert(ok, result)
	end)
end

---@param opts table | nil
function M.attach_session(opts)
	local remote_cwd_cmd = vim.fn.system("docker compose exec " .. container .. " pwd")
	local remote_cwd = string.gsub(remote_cwd_cmd, "\n", "")
	local mappings = {
		{
			localRoot = local_cwd,
			remoteRoot = remote_cwd,
		},
	}
	if container == "shared_payload_data_api" or container == "shared_payload_load_data" then
		if not os.getenv("LOCAL_MODELS_PATH") then
			vim.notify("The LOCAL_MODELS_PATH environment variable is not set")
			os.exit()
		else
			table.insert(mappings, {
				localRoot = os.getenv("LOCAL_MODELS_PATH"),
				remoteRoot = remote_cwd .. "/vareto_pydantic_models",
			})
		end
	end

	opts = vim.tbl_extend("keep", opts or {}, { console = "integratedTerminal", path_mappings = mappings })

	local function host_function(host)
		vim.notify("Attaching " .. name .. " to: " .. host .. ":" .. port)
		local config = {
			type = "python",
			request = "attach",
			name = name,
			connect = { host = host, port = port },
			console = opts.console,
			cwd = local_cwd,
			pathMappings = opts.path_mappings,
		}
		load_dap().run(config)
	end

	if not opts.host then
		get_host(host_function)
	else
		host_function(opts.host)
	end
end

return M
