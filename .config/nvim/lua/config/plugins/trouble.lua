return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    config = function()
        vim.keymap.set("n", "<leader>tt", function() require("trouble").toggle("workspace_diagnostics") end, { desc = "Toggle Diagnostics Window" })
        vim.keymap.set("n", "[t", function() require("trouble").previous({skip_groups = true, jump = true}) end, { desc = "Prev Diagnostic" })
        vim.keymap.set("n", "]t", function() require("trouble").next({skip_groups = true, jump = true}) end, { desc = "Next Diagnostic" })
    end,
}
