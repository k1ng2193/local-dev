return {
    "mbbill/undotree",
    event = { "BufEnter", "BufNewFile" },
    config = function()
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle Undo Window" })
    end,
}
