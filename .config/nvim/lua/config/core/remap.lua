vim.g.mapleader = " "

local opts = { noremap = true, silent = true, }

opts.desc = "SSO prod"
vim.keymap.set("n", "<leader>sso", function() require("config.core.docker").get_docker_dependencies() end, opts)
opts.desc = "CodeArtifact"
vim.keymap.set("n", "<leader>art", function() require("config.core.local_dev").artifact() end, opts)
opts.desc = "Docker Login"
vim.keymap.set("n", "<leader>dl", function() require("config.core.local_dev").docker_login() end, opts)

opts.desc = "Show Yank Register"
vim.keymap.set("n", "<leader>rg", ":reg<CR>", opts)

opts.desc = "Clear Search Highlights"
vim.keymap.set("n", "<leader>nh", ":nohl<CR>", opts)

opts.desc = "Increment Number"
vim.keymap.set("n", "<leader>+", "<C-a>", opts)
opts.desc = "Decrement Number"
vim.keymap.set("n", "<leader>-", "<C-x>", opts)

opts.desc = "Decrease Width"
vim.keymap.set("n", "<leader>h", "<C-w>10<", opts)
opts.desc = "Increase Width"
vim.keymap.set("n", "<leader>l", "<C-w>10>", opts)
opts.desc = "Decrease Height"
vim.keymap.set("n", "<leader>j", "<C-w>10-", opts)
opts.desc = "Increase Height"
vim.keymap.set("n", "<leader>k", "<C-w>10+", opts)
opts.desc = "Split Vertically"
vim.keymap.set("n", "|", "<C-w>H", opts)
opts.desc = "Split Horizontally"
vim.keymap.set("n", "_", "<C-w>K", opts)
opts.desc = "Split Current Window Vertically"
vim.keymap.set("n", "<leader>|", "<C-w>v", opts)
opts.desc = "Split Current Window Horizontally"
vim.keymap.set("n", "<leader>_", "<C-w>s", opts)
opts.desc = "Make Splits Equal"
vim.keymap.set("n", "<leader>e", "<C-w>=", opts)
opts.desc = "Close Split"
vim.keymap.set("n", "<leader><BS>", ":close<CR>", opts)
opts.desc = "Maximize Window"
vim.keymap.set("n", "<leader>o", ":only<CR>", opts)

opts.desc = "Navigate Left"
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
opts.desc = "Navigate Down"
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
opts.desc = "Navigate Up"
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
opts.desc = "Navigate Right"
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

opts.desc = "Move Highlighted Lines Up"
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", opts)
opts.desc = "Move Highlighted Lines Down"
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", opts)

opts.desc = "Join Next Line"
vim.keymap.set("n", "<leader>c", "mzJ`z", opts)

opts.desc = "Paste Without Replacing Register"
vim.keymap.set("x", "<leader>p", "\"_dP", opts)
opts.desc = "Delete Without Replacing Register"
vim.keymap.set("n", "<C-d>", "\"_d", opts)
opts.desc = "Delete Without Replacing Register"
vim.keymap.set("v", "<C-d>", "\"_d", opts)

opts.desc = "No Action"
vim.keymap.set("n", "Q", "<nop>", opts)

opts.desc = "Grant File Permissions"
vim.keymap.set("n", "<leader>xp", "<cmd>!chmod +x %<CR>", opts)

opts.desc = "Open QuickFix List"
vim.keymap.set("n", "<leader>qf", ":copen<CR>", opts)
vim.cmd[[
    augroup quickfix_keymap
        autocmd!
        autocmd FileType qf lua vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<CR>:cclose<CR>", {})
        augroup END
]]
opts.desc = "Clear QuickFix List"
vim.keymap.set("n", "<leader>qc", ":cexpr []<CR>", opts)

opts.desc = "Toggle File Explorer"
vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", opts)
opts.desc = "Toggle File Explorer With Current File"
vim.keymap.set("n", "<leader>tf", ":NvimTreeFindFileToggle<CR>", opts)

opts.desc = "Run Docker Pytest for Function"
vim.keymap.set("n", "<leader>dm", function() require("config.core.docker").run_pytest({ type = "function" }) end, opts)
opts.desc = "Run Docker Pytest for File"
vim.keymap.set("n", "<leader>df", function() require("config.core.docker").run_pytest({ type = "file" }) end, opts)
opts.desc = "Run Docker All Pytest"
vim.keymap.set("n", "<leader>dpy", function() require("config.core.docker").run_pytest({ type = "all" }) end, opts)
opts.desc = "Attach to Docker"
vim.keymap.set("n", "<leader>da", function() require("config.core.docker").attach_session() end, opts)

opts.desc = "Docker Show Containers"
vim.keymap.set("n", "<leader>ds", function() require("config.core.docker").show_containers() end, opts)
opts.desc = "Docker Image List"
vim.keymap.set("n", "<leader>dil", function() require("config.core.docker").list_image() end, opts)
opts.desc = "Docker Image Prune"
vim.keymap.set("n", "<leader>dpi", function() require("config.core.docker").prune_image() end, opts)
opts.desc = "Docker Volume Prune"
vim.keymap.set("n", "<leader>dpv", function() require("config.core.docker").prune_volume() end, opts)
opts.desc = "Docker System Prune"
vim.keymap.set("n", "<leader>dps", function() require("config.core.docker").prune_system() end, opts)
opts.desc = "Docker Compose Build"
vim.keymap.set("n", "<leader>dcb", function() require("config.core.docker").build_containers() end, opts)
opts.desc = "Docker Compose Up"
vim.keymap.set("n", "<leader>dcu", function() require("config.core.docker").start_containers() end, opts)
opts.desc = "Docker Compose Down"
vim.keymap.set("n", "<leader>dcd", function() require("config.core.docker").stop_containers() end, opts)
opts.desc = "Docker Compose Kill Single Container"
vim.keymap.set("n", "<leader>dck", function() require("config.core.docker").kill_container() end, opts)
opts.desc = "Docker Remove Container"
vim.keymap.set("n", "<leader>drm", function() require("config.core.docker").remove_container() end, opts)
opts.desc = "Docker Remove Image"
vim.keymap.set("n", "<leader>dri", function() require("config.core.docker").remove_image() end, opts)

opts.desc = "Toggle Inlay Hint"
vim.keymap.set("n", "<leader>i", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, opts)

opts.desc = "Create GH Pull Request"
vim.keymap.set("n", "<leader>ghpc", function() require("config.core.gh").create_pr() end, opts)
opts.desc = "Create GH Pull Request"
vim.keymap.set("n", "<leader>te", function() require("config.core.gh").test() end, opts)

opts.silent = false
opts.desc = "Search and Replace Yanked"
vim.keymap.set("n", "<C-s>y", [[:%s/<C-r><C-w>/<C-r>0/gI<Left><Left><Left>]], opts)
opts.desc = "Search and Replace Cursor"
vim.keymap.set("n", "<C-s>", [[:%s/<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)
opts.desc = "Search and Replace Yanked QuickFix"
vim.keymap.set("n", "<C-s>r", [[:cdo %s/<C-r><C-w>/<C-r>0/gcI<Left><Left><Left>]], opts)

opts.desc = "Debugger Rust Testables"
vim.keymap.set("n", "<leader>drt", function() vim.cmd("RustLsp testables") end, opts)
