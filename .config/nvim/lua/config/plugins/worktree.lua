return {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    event = { "BufEnter", "BufNewFile" },
    config = function()
        local work_tree = require("git-worktree")
        local utils = require("config.core.utils")
        work_tree.setup({
            change_directory_command = "cd",
            update_on_change = true,
            update_on_change_command = "e .",
            clearjumps_on_change = true,
            autopush = false,
        })

        work_tree.on_tree_change(function(op, metadata)
            if op == work_tree.Operations.Create then
                print("Created " .. metadata.branch .. " branch tracking " .. metadata.upstream)
            end

            if op == work_tree.Operations.Switch then
                print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
                utils.deactivate_venv()
                -- utils.activate_venv()
            end
        end)

        require("telescope").load_extension("git_worktree")

        vim.keymap.set("n", "<leader>fw", ":lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", { noremap = true, silent = true, desc = "Switch and Delete Git Worktree" })
        vim.keymap.set("n", "<leader>wc", ":lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>", { noremap = true, silent = true, desc = "Create Git Worktree" })
    end,
}
