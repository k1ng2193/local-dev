return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require("gitsigns").setup()

        vim.keymap.set("n", "[h", ":Gitsigns prev_hunk<CR>", { noremap = true, desc = "Previous Hunk" })
        vim.keymap.set("n", "]h", ":Gitsigns next_hunk<CR>", { noremap = true, desc = "Next Hunk" })
        vim.keymap.set("n", "<leader>sb", ":Gitsigns stage_buffer<CR>", { noremap = true, desc = "Stage Buffer" })
        vim.keymap.set("n", "<leader>sh", ":Gitsigns stage_hunk<CR>", { noremap = true, desc = "Stage Hunk" })
        vim.keymap.set("n", "<leader>su", ":Gitsigns undo_stage_hunk<CR>", { noremap = true, desc = "Undo Stage Hunk" })
        vim.keymap.set("n", "<leader>rb", ":Gitsigns reset_buffer<CR>", { noremap = true, desc = "Reset Buffer" })
        vim.keymap.set("n", "<leader>ph", ":Gitsigns preview_hunk<CR>", { noremap = true, desc = "Preview Hunk" })
        vim.keymap.set("n", "<leader>td", ":Gitsigns toggle_deleted<CR>", { noremap = true, desc = "Toggle Deleted" })
    end,
}
