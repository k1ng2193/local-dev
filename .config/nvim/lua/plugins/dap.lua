local function get_project_root()
  local cwd = vim.fn.getcwd()
  local root_path = vim.fs.find({ ".venv", "uv.lock", "pyproject.toml" }, { upward = false, limit = 1, path = cwd })
  return vim.fs.dirname(root_path[1]) or cwd
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "theHamsta/nvim-dap-virtual-text",
    "mfussenegger/nvim-dap-python",
  },
  config = function()
    local dap = require("dap")
    local dappy = require("dap-python")

    dap.set_log_level("TRACE")

    vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })
    vim.fn.sign_define("DapStopped", { text = "🤔", texthl = "", linehl = "", numhl = "" })

    dappy.setup("uv")
    dappy.test_runner = "pytest"

    vim.keymap.set("n", "<leader>bp", function()
      dap.toggle_breakpoint()
    end, { noremap = true, silent = true, desc = "Toggle Breakpoint" })
    vim.keymap.set("n", "<leader>dd", function()
      dap.clear_breakpoints()
    end, { noremap = true, silent = true, desc = "Clear Breakpoints" })
    vim.keymap.set("n", "<S-k>", function()
      dap.step_out()
    end, { noremap = true, silent = true, desc = "Step Out" })
    vim.keymap.set("n", "<S-l>", function()
      dap.step_into()
    end, { noremap = true, silent = true, desc = "Step Into" })
    vim.keymap.set("n", "<S-j>", function()
      dap.step_over()
    end, { noremap = true, silent = true, desc = "Step Over" })
    vim.keymap.set("n", "<leader>dq", function()
      dap.close()
    end, { noremap = true, silent = true, desc = "Stop Debugger" })
    vim.keymap.set("n", "<leader>dn", function()
      dap.continue()
    end, { noremap = true, silent = true, desc = "Open/Continue Debugger" })
    vim.keymap.set("n", "<leader>dk", function()
      dap.up()
    end, { noremap = true, silent = true, desc = "Move Up Stack Frame" })
    vim.keymap.set("n", "<leader>dj", function()
      dap.down()
    end, { noremap = true, silent = true, desc = "Move Down Stack Frame" })
    vim.keymap.set("n", "<leader>du", function()
      dap.run_last()
    end, { noremap = true, silent = true, desc = "Run Last Configuration" })
    vim.keymap.set("n", "<leader>dr", function()
      dap.repl.open({}, "vsplit")
    end, { noremap = true, silent = true, desc = "Open REPL" })
    vim.keymap.set("n", "<leader>d?", function()
      local widgets = require("dap.ui.widgets")
      widgets.centered_float(widgets.scopes)
    end, { noremap = true, silent = true, desc = "Scopes Hover Window" })
    vim.keymap.set("n", "<leader>de", function()
      dap.set_exception_breakpoints { "all" }
    end, { noremap = true, silent = true, desc = "Exception Breakpoints" })

    -- vim.keymap.set("n", "<leader>df", function() dappy.test_method() end, { noremap = true, silent = true, desc = "Test Method" })
    -- vim.keymap.set("n", "<leader>dc", function() dappy.test_class() end, { noremap = true, silent = true, desc = "Test Class" })
    -- vim.keymap.set("n", "<leader>ds", function() dappy.debug_selection() end, { noremap = true, silent = true, desc = "Test Selection" })

    table.insert(dap.configurations.python, {
      type = "python",
      request = "launch",
      name = "Launch Pipeline Configuration",
      program = "${file}",
      args = function()
        local args_string = vim.fn.input("Arguments: ")
        -- Check if the user entered any arguments
        if args_string and args_string ~= "" then
          -- Split the string into individual arguments using spaces as separators
          return vim.split(args_string, " ")
        else
          -- If the user didn't enter any arguments, return an empty table
          return {}
        end
      end,
      env = function()
        local environment = vim.fn.input("Environment: "):lower()
        if environment == "prod" or environment == "release" or environment == "staging" then
          return {
            RECORD_BUCKET_NAME = environment .. "-integration-record-us-west-2",
            GOLD_BUCKET_NAME = environment .. "-integration-gold-us-west-2",
          }
        else
          error("Invalid environment")
        end
      end,
      console = "integratedTerminal",
    })

    table.insert(dap.configurations.python, {
      type = "python",
      request = "attach",
      name = "Attach Data API",
      connect = function()
        vim.notify(get_project_root())
        local host = vim.fn.input("Host [127.0.0.1]: ")
        host = host ~= "" and host or "127.0.0.1"
        local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
        return { host = host, port = port }
      end,
      cwd = function() get_project_root() end,
      pathMappings = {
        {
          localRoot = function() get_project_root() end,
          remoteRoot = "/code",
        },
      },
    })

    table.insert(dap.configurations.python, {
      type = "python",
      request = "attach",
      name = "Attach Shared Payload Data API",
      connect = function()
        local host = vim.fn.input("Host [127.0.0.1]: ")
        host = host ~= "" and host or "127.0.0.1"
        local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
        return { host = host, port = port }
      end,
      cwd = get_project_root(),
      pathMappings = {
        {
          localRoot = get_project_root(),
          remoteRoot = "/code",
        },
        {
          localRoot = "~/vareto-repo/shared-payload-models/vareto_pydantic_models",
          remoteRoot = "/code/vareto_pydantic_models",
        },
      },
    })

    require("nvim-dap-virtual-text").setup {
      enabled = true, -- enable this plugin (the default)
      enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
      highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
      highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
      show_stop_reason = true, -- show stop reason when stopped for exceptions
      commented = false, -- prefix virtual text with comment string
      only_first_definition = true, -- only show virtual text at first definition (if there are multiple)
      all_references = false, -- show virtual text on all all references of the variable (not only definitions)
      clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
      --- A callback that determines how a variable is displayed or whether it should be omitted
      --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
      --- @param _buf number
      --- @param _stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
      --- @param _node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
      --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
      --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
      display_callback = function(variable, _buf, _stackframe, _node, options)
        if options.virt_text_pos == "inline" then
          return " = " .. variable.value
        else
          return variable.name .. " = " .. variable.value
        end
      end,
      -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
      virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",

      -- experimental features:
      all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
      virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
      virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
      -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
    }
  end,
}
