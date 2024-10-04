local M = {}
local Menu = require("nui.menu")

local menu_size = {
    position = "50%",
    size = {
        width = "20%",
        height = 7,
    },
    border = {
        style = "rounded",
        text = {
            top = "[Select AWS Profile]",
            top_align = "center",
        }
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

---@param cb function | nil
function M.sso(cb)
    local lines = {}
    local profiles = vim.fn.system("grep '^\\[profile' ~/.aws/config | cut -d ' ' -f 2 | tr -d '[]' | sort")
    for prof in profiles:gmatch("[^\r\n]+") do
        table.insert(lines, Menu.item(prof))
    end

    local profiles_menu_config = {
        lines = lines,
        on_close = function()
            vim.notify("No Profile Selected")
        end,
        on_submit = function(item)
            local profile = item.text
            vim.env.AWS_PROFILE = profile
            local result = vim.fn.system("aws sso login")
            print(result)
            if cb then
                cb()
            end
        end,
    }
    profiles_menu_config = vim.tbl_extend("force", menu_config, profiles_menu_config)
    local profiles_menu = Menu(menu_size, profiles_menu_config)
    profiles_menu:mount()
end

function M.artifact()
    local cmd = "aws codeartifact get-authorization-token --domain vareto --domain-owner 544138963155 --query authorizationToken --output text"
    local token_list = vim.fn.systemlist(cmd)
    local token = token_list[1] -- Extract the first line of output
    if token_list and token_list[1] ~= "" then
        local config_cmd = "pip config set global.index-url 'https://aws:" ..
            token .. "@vareto-544138963155.d.codeartifact.us-west-2.amazonaws.com/pypi/vareto-python/simple'"
        local result = vim.fn.system(config_cmd)
        print(result) -- Print the result of the second command
        vim.fn.system("cp ~/.config/pip/pip.conf pip.conf")
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
