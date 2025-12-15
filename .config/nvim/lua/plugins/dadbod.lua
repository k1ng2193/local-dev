return {
  "kristijanhusak/vim-dadbod-ui",
  keys = {
    { "<leader>db", ":DBUIToggle<CR>", noremap = true, silent = true, desc = "Toggle DB UI" },
  },
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  config = function()
    vim.g.db_ui_use_nerd_fonts = 1

    -- local cmp = require("cmp")
    --
    -- -- autocmd FileType sql,mysql,plsql lua require("cmp").setup.buffer({ sources = {{ name = "vim-dadbod-completion" }} })
    -- vim.api.nvim_create_autocmd("FileType", {
    --     pattern = { "sql", "mysql", "plsql" },
    --     callback = function()
    --         cmp.setup.buffer {
    --             sources = {
    --                 { name = "vim-dadbod-completion" }
    --             }
    --         }
    --     end,
    -- })

    vim.keymap.set(
      "n",
      "<leader><CR>",
      "<Plug>(DBUI_ExecuteQuery)",
      { noremap = true, silent = true, desc = "Execute Query" }
    )
    vim.keymap.set(
      "v",
      "<leader><CR>",
      "<Plug>(DBUI_ExecuteQuery)",
      { noremap = true, silent = true, desc = "Execute Query" }
    )
  end,
}
