local M = {}
local utils = require("config.core.utils")
local dev = require("config.core.local_dev")
local Menu = require("nui.menu")

local container
local port
local name
local network
local local_cwd
local default_port = { port = "5678" }

local menu_size = {
	position = "50%",
	size = {
		width = "20%",
		height = 7,
	},
	border = {
		style = "rounded",
		text = {
			top = "[Select Docker Service]",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:Normal,FloatBorder:Normal",
	},
}

local menu_config = {
	max_width = 20,
	keymap = {
		focus_next = { "<C-j>", "j", "<Down>", "<Tab>" },
		focus_prev = { "<C-k>", "k", "<Up>", "<S-Tab>" },
		close = { "<Esc>", "<C-c>" },
		submit = { "<CR>", "<Space>" },
	},
}

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
	-- local popup = Popup({
	-- 	enter = true,
	-- 	focusable = true,
	-- 	border = {
	-- 		style = "rounded",
	-- 	},
	-- 	position = {
	-- 		row = "25%",
	-- 		col = 0,
	-- 	},
	-- 	size = {
	-- 		width = "100%",
	-- 		height = "50%",
	-- 	},
	-- 	anchor = "SW",
	-- 	relative = "editor",
	-- })
	-- local opts = { popup = popup }
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
				-- update_popup_content(opts, data)
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
				-- local stdout_message = table.concat(stdout_data)
				vim.notify("Successfully executed docker command: " .. docker_command)
				-- vim.notify(stdout_message)
				if type(cb) == "function" then
					cb()
				end
			else
				vim.env.AWS_PROFILE = nil
				vim.notify("Failed to execute docker command: " .. docker_command, 4)
				-- vim.notify(stderr_message, 4)
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
		-- local output = ""
		-- local job_id = vim.fn.jobstart(docker_command, {
		--     on_stdout = function(_, data, _)
		--         output = output .. data
		--     end,
		-- on_exit = function(_, _, _)
		--     callback(opts)
		-- coroutine.yield(output) -- Resume the coroutine and pass the output
		-- end
		-- })
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
		local lines = {}
		local services = vim.fn.system("yq eval '.services | keys | .[]' " .. docker_compose_filepath)
		for service in services:gmatch("[^\r\n]+") do
			table.insert(lines, Menu.item(service))
		end

		local services_menu_config = {
			lines = lines,
			on_close = function()
				vim.notify("No Service Selected")
			end,
			on_submit = function(item)
				container = item.text
				cb()

				-- if container == "js_interop" or container == "shared_payload_js_interop" then
				-- 	local ssh = vim.fn.system("ssh-add -L")
				-- 	if ssh == "The agent has no identities." then
				-- 		local add_ssh = vim.fn.system("ssh-add --apple-use-keychain ~/.ssh/id_ssh")
				-- 		vim.notify(add_ssh)
				-- 	end
				-- end
			end,
		}
		services_menu_config = vim.tbl_extend("force", menu_config, services_menu_config)
		local services_menu = Menu(menu_size, services_menu_config)
		services_menu:mount()
	end
end

local function get_docker_containers(cb)
	local lines = {}
	local containers = vim.fn.system("docker ps --format '{{.Names}}'")
	for cont in containers:gmatch("[^\r\n]+") do
		table.insert(lines, Menu.item(cont))
	end

	local container_menu_config = {
		lines = lines,
		on_close = function()
			vim.notify("No Container Selected")
		end,
		on_submit = function(item)
			cb(item.text)
		end,
	}
	container_menu_config = vim.tbl_extend("force", menu_config, container_menu_config)
	local container_menu = Menu(menu_size, container_menu_config)
	container_menu:mount()
end

local function get_host(cb)
	local host_input_config = {
		position = "50%",
		size = {
			width = 25,
		},
		border = {
			style = "single",
			text = {
				top = "[Host Address]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}
	local host_input_prompt = {
		prompt = "> ",
		default_value = "127.0.0.1",
		on_close = function()
			vim.notify("Please input a host address")
		end,
		on_submit = function(value)
			cb(value)
		end,
	}
	utils.mount_input(host_input_config, host_input_prompt)
end

---@param local_port string | nil
local function get_port_and_attach(local_port)
	local input_port
	if local_port == nil then
		input_port = default_port.port
	else
		input_port = local_port
	end

	local port_input_config = {
		position = "50%",
		size = {
			width = 20,
		},
		border = {
			style = "single",
			text = {
				top = "[Port]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}
	local port_input_prompt = {
		prompt = "> ",
		default_value = input_port,
		on_close = function()
			vim.notify("Please input a port")
		end,
		on_submit = function(value)
			port = tonumber(value)
			vim.notify("Attempting to attach to container at port: " .. port)
			if type(port) == "integer" then
				disconnect_old_session(port)
			end

			vim.defer_fn(function()
				M.attach_session({ host = "127.0.0.1" })
			end, 5000)
		end,
	}

	local attach_menu_config = {
		lines = { Menu.item("Yes"), Menu.item("No") },
		on_close = function()
			vim.notify("No Option Selected")
		end,
		on_submit = function(item)
			if item.text == "Yes" then
				utils.mount_input(port_input_config, port_input_prompt)
			end
		end,
	}

	local attach_menu_size = {
		position = "50%",
		size = {
			width = "15%",
			height = 2,
		},
		border = {
			style = "rounded",
			text = {
				top = "[Attach Debugger]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}

	attach_menu_config = vim.tbl_extend("force", menu_config, attach_menu_config)
	local attach_menu = Menu(attach_menu_size, attach_menu_config)
	attach_menu:mount()
end

local function get_shared_payloads_path(cb)
	if
		container == "shared_payload_data_api"
		or (container == "shared_payload_load_data" and not vim.env.LOCAL_MODELS_PATH)
	then
		local home_dir = os.getenv("HOME") or "~"
		local shared_input_config = {
			position = "50%",
			size = {
				width = 75,
			},
			border = {
				style = "single",
				text = {
					top = "[Shared Payload Models Path]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}
		local shared_input_prompt = {
			prompt = "> ",
			default_value = home_dir .. "/vareto-repo/shared-payload-models/vareto_pydantic_models",
			on_close = function()
				vim.notify("Please input a local path for the shared-payload-models repository")
			end,
			on_submit = function(value)
				vim.env.LOCAL_MODELS_PATH = value
				cb()
			end,
		}
		utils.mount_input(shared_input_config, shared_input_prompt)
	else
		cb()
	end
end

local function remove_docker_network()
	if network then
		local resp = vim.fn.system("docker network rm " .. network)
		vim.notify("The " .. network .. " docker network was removed: " .. resp)
		network = nil
	else
		local network_input_config = {
			position = "50%",
			size = {
				width = 25,
			},
			border = {
				style = "single",
				text = {
					top = "[Docker Network]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}
		local network_input_prompt = {
			prompt = "> ",
			default_value = "vareto",
			on_close = function()
				vim.notify("Please input a docker network")
			end,
			on_submit = function(value)
				local resp = vim.fn.system("docker network rm " .. value)
				vim.notify("The " .. value .. " docker network was removed: " .. resp)
			end,
		}
		utils.mount_input(network_input_config, network_input_prompt)
	end
end

-- Function to check if all containers are up and running
---@param message string
---@param up boolean
---@param delay integer
---@param cb function
---@param on_complete function | nil
local function check_containers(message, up, delay, cb, on_complete)
	local running = vim.fn.system("docker compose ps --services --filter 'status=running'")
	local exited = vim.fn.system("docker compose ps --services --filter 'status=exited'")

	local check_complete = false
	if running:gsub("^%s*(.-)%s*$", "%1") == "" or running == "" or running == "nil" then
		if up then
			vim.notify("No containers are running", 4)
			if StartUpTimer and not StartUpTimer:is_closing() then
				StartUpTimer:close()
			end
		else
			vim.notify("All containers have been shut down")
			container = nil

			-- vim.defer_fn(function()
			-- remove_docker_network()
			-- end, 30000)

			if ShutDownTimer and not ShutDownTimer:is_closing() then
				ShutDownTimer:close()
			end
		end

		check_complete = true
	end

	if up then
		-- Split the result into lines
		local lines = {}
		for running_line in running:gmatch("[^\r\n]+") do
			table.insert(lines, running_line)
		end
		for exited_line in exited:gmatch("[^\r\n]+") do
			table.insert(lines, exited_line)
		end

		for _, line in ipairs(lines) do
			if line == container then
				vim.notify("All containers are up and running.")
				check_complete = true

				if StartUpTimer and not StartUpTimer:is_closing() then
					StartUpTimer:close()
				end
			end
		end
	end

	if not check_complete then
		vim.notify(message)

		-- Reschedule the function to run again after a delay
		vim.defer_fn(function()
			cb(message, up, delay, check_containers)
		end, delay)
  elseif on_complete ~= nil then
    on_complete()
	end
end

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

		-- local attach_menu_config = {
		-- 	lines = { Menu.item("Yes"), Menu.item("No") },
		-- 	on_close = function()
		-- 		vim.notify("No Option Selected")
		-- 	end,
		-- 	on_submit = function(item)
		-- 		if item.text == "Yes" then
		-- 			vim.defer_fn(function()
		-- 				M.attach_session({ host = "127.0.0.1" })
		-- 			end, 20000)
		-- 		end
		-- 	end,
		-- }
		--
		-- local attach_menu_size = {
		-- 	position = "50%",
		-- 	size = {
		-- 		width = "10%",
		-- 		height = 2,
		-- 	},
		-- 	border = {
		-- 		style = "rounded",
		-- 		text = {
		-- 			top = "[Attach Debugger]",
		-- 			top_align = "center",
		-- 		},
		-- 	},
		-- 	win_options = {
		-- 		winhighlight = "Normal:Normal,FloatBorder:Normal",
		-- 	},
		-- }
		--
		-- attach_menu_config = vim.tbl_extend("force", menu_config, attach_menu_config)
		-- local attach_menu = Menu(attach_menu_size, attach_menu_config)
		-- attach_menu:mount()
	end)
	-- local function on_terminated(session, body)
	--     local lsession = session
	--     if (not lsession or not lsession.stopped_thread_id) and lsession.config.name == "Data API Pytest" then
	--         -- local local_file_path = local_cwd .. "/pytest_output.txt"
	--         update_popup_content()
	--         -- update_popup_content(local_file_path)
	--     end
	-- end
	--
	-- dap.defaults.python.exception_breakpoints = {}
	-- dap.listeners.after.event_terminated["pytest"] = on_terminated
end

---@param opts table | nil
---@param cb function | nil
local function create_docker_network(opts, cb)
	local network_input_config = {
		position = "50%",
		size = {
			width = 25,
		},
		border = {
			style = "single",
			text = {
				top = "[Docker Network]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}
	local network_input_prompt = {
		prompt = "> ",
		default_value = "vareto",
		on_close = function()
			vim.notify("Please input a docker network")
		end,
		on_submit = function(value)
			network = value
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
		end,
	}
	if network then
		local network_check = vim.fn.system("docker network ls --filter 'name=" .. network .. "' --format '{{.Name}}'")
		if network_check == "" then
			utils.mount_input(network_input_config, network_input_prompt)
		elseif opts and opts.action == "start" and type(cb) == "function" then
			get_docker_services(opts, cb)
		end
	else
		utils.mount_input(network_input_config, network_input_prompt)
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

		create_docker_network(opts, cb)
	end

	if not stat or stat.type ~= "file" or not vim.env.AWS_PROFILE then
		dev.sso(callback)
	else
		create_docker_network(opts, cb)
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

function M.prune_image()
	local image = vim.fn.system("docker image prune -f")

	vim.notify(image)
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
		local cache_menu_config = {
			lines = { Menu.item("Yes"), Menu.item("No") },
			on_close = function()
				vim.notify("No Option Selected")
			end,
			on_submit = function(item)
        local docker_command = string.format("docker compose build " .. container)
				if item.text == "No" then
				  docker_command = string.format(docker_command .. " --no-cache")
				end
        execute_docker_command(docker_command)
			end,
		}

		local cache_menu_size = {
			position = "50%",
			size = {
				width = "15%",
				height = 2,
			},
			border = {
				style = "rounded",
				text = {
					top = "[Build With Cache]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}

		cache_menu_config = vim.tbl_extend("force", menu_config, cache_menu_config)
		local attach_menu = Menu(cache_menu_size, cache_menu_config)
		attach_menu:mount()
	end)
end

---@param attach boolean
function M.start_containers(attach)
	if ShutDownTimer and not ShutDownTimer:is_closing() then
		ShutDownTimer:close()
	end

	name = "Data API"

	-- M.get_docker_dependencies({ action = "start" }, function()
	-- get_shared_payloads_path(function()
	get_docker_services({ action = "start" }, function()
		load_dap().defaults.python.exception_breakpoints = { "default" }
		local docker_command = string.format("docker compose up -d " .. container)
		-- local ok, result = pcall(execute_docker_command, docker_command, function()
		execute_docker_command(docker_command, function()
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
				check_containers(message, true, 15000, check_containers, on_complete)
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
		-- 		check_containers(message, true, 15000, check_containers)
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
		end, 60000) -- milliseconds

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

	local docker_command = string.format("docker compose down -v --remove-orphans")
	vim.notify("Shutting down all docker containers")
	local docker_coroutine = DockerCoroutine(docker_command)
	coroutine.resume(docker_coroutine)

	ShutDownTimer = vim.defer_fn(function()
		-- Terminate the process if it takes longer than 5 minutes
		vim.notify("Containers are taking too long to shutdown. Please check the container statuses manually.")
	end, 60000) -- milliseconds

	vim.notify("Checking container statuses...")

	local message = "Containers are still shutting down"
	-- Schedule the asynchronous function to be executed asynchronously in the next event loop iteration
	vim.defer_fn(function()
		check_containers(message, false, 10000, check_containers)
	end, 1000)
end

function M.remove_image()
	local lines = {}
	local images = vim.fn.system("docker image ls --format '{{.Repository}}'")
	for image in images:gmatch("[^\r\n]+") do
		table.insert(lines, Menu.item(image))
	end

	local image_menu_config = {
		lines = lines,
		on_close = function()
			vim.notify("No Image Selected")
		end,
		on_submit = function(item)
			local image = item.text

			local docker_command = string.format("docker image rm " .. image)
			local ok, result = pcall(execute_docker_command, docker_command)
			assert(ok, result)
		end,
	}
	image_menu_config = vim.tbl_extend("force", menu_config, image_menu_config)
	local image_menu = Menu(menu_size, image_menu_config)
	image_menu:mount()
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
