vim.g.mapleader = " "

local docker = require("core.docker")
local makeit = require("core.makeit")
local dev = require("core.dev")

local opts = { noremap = true, silent = true }

opts.desc = "SSO prod"
vim.keymap.set("n", "<leader>sso", function()
	docker.get_docker_dependencies()
end, opts)
opts.desc = "CodeArtifact"
vim.keymap.set("n", "<leader>art", function()
	dev.artifact()
end, opts)
opts.desc = "Docker Login"
vim.keymap.set("n", "<leader>dl", function()
	docker.docker_login()
end, opts)

-- opts.desc = "Show Yank Register"
-- vim.keymap.set("n", "<leader>rg", ":reg<CR>", opts)

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
vim.keymap.set("x", "<leader>p", '"_dP', opts)
opts.desc = "Delete Without Replacing Register"
vim.keymap.set("n", "<C-d>", '"_d', opts)
opts.desc = "Delete Without Replacing Register"
vim.keymap.set("v", "<C-d>", '"_d', opts)

opts.desc = "No Action"
vim.keymap.set("n", "Q", "<nop>", opts)

opts.desc = "Grant File Permissions"
vim.keymap.set("n", "<leader>xp", "<cmd>!chmod +x %<CR>", opts)

-- opts.desc = "Open QuickFix List"
-- vim.keymap.set("n", "<leader>qf", ":copen<CR>", opts)
-- vim.cmd[[
--     augroup quickfix_keymap
--         autocmd!
--         autocmd FileType qf lua vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<CR>:cclose<CR>", {})
--         augroup END
-- ]]

-- opts.desc = "Toggle File Explorer"
-- vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", opts)
-- opts.desc = "Toggle File Explorer With Current File"
-- vim.keymap.set("n", "<leader>tf", ":NvimTreeFindFileToggle<CR>", opts)

opts.desc = "Run Docker Pytest for Function"
vim.keymap.set("n", "<leader>dm", function()
	docker.run_pytest({ type = "function" })
end, opts)
opts.desc = "Run Docker Pytest for File"
vim.keymap.set("n", "<leader>df", function()
	docker.run_pytest({ type = "file" })
end, opts)
opts.desc = "Run Docker All Pytest"
vim.keymap.set("n", "<leader>dpy", function()
	docker.run_pytest({ type = "all" })
end, opts)
opts.desc = "Attach to Docker"
vim.keymap.set("n", "<leader>da", function()
	docker.attach_session()
end, opts)

opts.desc = "Docker Show Containers"
vim.keymap.set("n", "<leader>ds", function()
	docker.show_containers()
end, opts)
opts.desc = "Docker Image List"
vim.keymap.set("n", "<leader>dil", function()
	docker.list_image()
end, opts)
opts.desc = "Docker Network List"
vim.keymap.set("n", "<leader>dnl", function()
	docker.list_network()
end, opts)
opts.desc = "Docker Volume List"
vim.keymap.set("n", "<leader>dvl", function()
	docker.list_volume()
end, opts)
opts.desc = "Docker Build Cache Prune"
vim.keymap.set("n", "<leader>dpb", function()
	docker.prune_build_cache()
end, opts)
opts.desc = "Docker Image Prune"
vim.keymap.set("n", "<leader>dpi", function()
	docker.prune_image()
end, opts)
opts.desc = "Docker Network Prune"
vim.keymap.set("n", "<leader>dpn", function()
	docker.prune_network()
end, opts)
opts.desc = "Docker Volume Prune"
vim.keymap.set("n", "<leader>dpv", function()
	docker.prune_volume()
end, opts)
opts.desc = "Docker System Prune"
vim.keymap.set("n", "<leader>dps", function()
	docker.prune_system()
end, opts)
opts.desc = "Docker Container Prune"
vim.keymap.set("n", "<leader>dpc", function()
	docker.prune_container()
end, opts)
opts.desc = "Docker Compose Build"
vim.keymap.set("n", "<leader>dcb", function()
	docker.build_containers()
end, opts)
opts.desc = "Docker Compose Up"
vim.keymap.set("n", "<leader>dcu", function()
	docker.start_containers(false)
end, opts)
opts.desc = "Docker Compose Up and Attach"
vim.keymap.set("n", "<leader>dca", function()
	docker.start_containers(true)
end, opts)
opts.desc = "Docker Compose Down"
vim.keymap.set("n", "<leader>dcd", function()
	docker.stop_containers()
end, opts)
opts.desc = "Docker Compose Kill Single Container"
vim.keymap.set("n", "<leader>dck", function()
	docker.kill_container()
end, opts)
opts.desc = "Docker Remove Container"
vim.keymap.set("n", "<leader>drc", function()
	docker.remove_container()
end, opts)
opts.desc = "Docker Remove Image"
vim.keymap.set("n", "<leader>dri", function()
	docker.remove_image()
end, opts)
opts.desc = "Docker Remove network"
vim.keymap.set("n", "<leader>drn", function()
	docker.remove_network()
end, opts)

opts.desc = "Redo Last Makeit Task"
vim.keymap.set("n", "<leader>mr", function()
	makeit.make_redo()
end, opts)

opts.desc = "Toggle Inlay Hint"
vim.keymap.set("n", "<leader>i", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, opts)

opts.desc = "Create GH Pull Request"
vim.keymap.set("n", "<leader>ghpc", function()
	require("core.gh").create_pr()
end, opts)

opts.silent = false
opts.desc = "Search and Replace Yanked"
vim.keymap.set("n", "<C-s>y", [[:%s/<C-r><C-w>/<C-r>0/gI<Left><Left><Left>]], opts)
opts.desc = "Search and Replace Cursor"
vim.keymap.set("n", "<C-s>", [[:%s/<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)
opts.desc = "Search and Replace Yanked QuickFix"
vim.keymap.set("n", "<C-s>r", [[:cdo %s/<C-r><C-w>/<C-r>0/gcI<Left><Left><Left>]], opts)

opts.desc = "Debugger Rust Testables"
vim.keymap.set("n", "<leader>drt", function()
	vim.cmd("RustLsp testables")
end, opts)

opts.desc = "Yank to System Clipboard"
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y<CR>', opts)

opts.desc = "Delete to System Clipboard"
vim.keymap.set({ "n", "v" }, "<leader>d", '"+d<CR>', opts)

opts.desc = "Clean Buffers and Restart LSP"
vim.keymap.set('n', '<leader>lc', ':CleanAndRestartLsp<CR>', opts)
