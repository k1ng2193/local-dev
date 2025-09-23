return {
    "ThePrimeagen/harpoon",
    config = function()
        local mark = require("harpoon.mark")
        local ui = require("harpoon.ui")

        vim.keymap.set("n", "<leader>a", function () mark.add_file() end, { desc = "Mark File" })
        vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu, { desc = "Toggle Harpoon Menu" })

        local opts = { noremap = true, silent = true }
        vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end, opts)
        vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end, opts)
        vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end, opts)
        vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end, opts)
        vim.keymap.set("n", "<leader>5", function() ui.nav_file(5) end, opts)
        vim.keymap.set("n", "<leader>6", function() ui.nav_file(6) end, opts)
        vim.keymap.set("n", "<leader>7", function() ui.nav_file(7) end, opts)
        vim.keymap.set("n", "<leader>8", function() ui.nav_file(8) end, opts)
        vim.keymap.set("n", "<leader>9", function() ui.nav_file(9) end, opts)
        vim.keymap.set("n", "<leader>0", function() ui.nav_file(10) end, opts)
    end,
}
