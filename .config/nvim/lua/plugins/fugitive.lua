local utils = require("core.utils")
local win_utils = require("core.win")

local uv = vim.uv
local api = vim.api

---@param git_args string[]
---@param auto_close boolean?
---@param wrap boolean?
local function async_git(git_args, auto_close, wrap)
  ---@type JobConfig
  local cfg = { cmd = "git", args = git_args, cwd = vim.fn.FugitiveWorkTree() }

  utils.execute_job({ job = cfg, auto_close = auto_close }, wrap)
end

---@param base_args string[]
---@param prompt string
---@param auto_close boolean?
---@param wrap boolean?
local function async_git_with_input(base_args, prompt, auto_close, wrap)
  local input = vim.fn.input(prompt)

  if input == "" then
    return
  end

  table.insert(base_args, input)

  async_git(base_args, auto_close, wrap)
end

return {
  "tpope/vim-fugitive",
  config = function()
    vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { noremap = true, silent = true, desc = "Git Status" })
    vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { noremap = true, silent = true, desc = "Git Blame" })
    -- vim.keymap.set("n", "<leader>gd", ":Gvdiff", { noremap = true, desc = "Git Diff" })
    vim.keymap.set("n", "<leader>ga", ":Gwrite<CR>", { noremap = true, silent = true, desc = "Git Stage All" })
    -- vim.keymap.set("n", "<leader>gl", ":Git log<CR>", { noremap = true, silent = true, desc = "Git Log" })
    vim.keymap.set("n", "<leader>gf", ":Git fetch<CR>", { noremap = true, desc = "Git Fetch" })
    vim.keymap.set("n", "<leader>gi", ":Git switch ", { noremap = true, desc = "Git Switch" })
    vim.keymap.set("n", "<leader>gco", function()
      async_git_with_input({ "commit", "-m" }, "Commit Message: ", true, true)
    end, { noremap = true, desc = "Git Commit" })
    vim.keymap.set("n", "<leader>gca", function()
      async_git_with_input({ "commit", "-a", "-m" }, "Commit Message: ", true, true)
    end, { noremap = true, desc = "Git Commit All" })
    -- vim.keymap.set("n", "<leader>gco", ":Git commit -m ", { noremap = true, desc = "Git Commit" })
    -- vim.keymap.set("n", "<leader>gca", ":Git commit -a -m ", { noremap = true, desc = "Git Commit All" })
    vim.keymap.set("n", "<leader>gds", ":vertical rightbelow Gdiffsplit", { noremap = true, desc = "Git Diff Split" })
    vim.keymap.set("n", "<leader>gm", ":Git merge ", { noremap = true, desc = "Git Merge" })
    vim.keymap.set("n", "<leader>gr", ":Git pull --rebase<CR>", { noremap = true, silent = true, desc = "Git Rebase" })
    vim.keymap.set("n", "<leader>gp", ":Git pull<CR>", { noremap = true, silent = true, desc = "Git Pull" })
    vim.keymap.set("n", "<leader>gw", function()
      async_git({ "push" }, true, true)
    end, { noremap = true, silent = true, desc = "Git Push" })
    vim.keymap.set("n", "<leader>go", function()
      async_git({ "push", "-u", "origin", "HEAD" }, true, true)
    end, { noremap = true, silent = true, desc = "Git Push Origin" })
    -- vim.keymap.set("n", "<leader>gw", ":Git push<CR>", { noremap = true, silent = true, desc = "Git Push" })
    -- vim.keymap.set(
    --   "n",
    --   "<leader>go",
    --   ":Git push -u origin HEAD<CR>",
    --   { noremap = true, silent = true, desc = "Git Push Origin" }
    -- )
    vim.keymap.set("n", "<leader>gx", ":Git stash -m ", { noremap = true, desc = "Git Stash" })
    vim.keymap.set("n", "<leader>gu", ":Git restore ", { noremap = true, desc = "Git Restore" })
    vim.keymap.set("n", "<leader>gc", ":Git checkout -b kenny/", { noremap = true, desc = "Git Create Branch" })
    vim.keymap.set("n", "<leader>gsm", function()
      async_git({ "submodule", "update", "--init" }, true, true)
    end, { noremap = true, silent = true, desc = "Git Push Origin" })
    -- vim.keymap.set("n", "<leader>gsm", ":Git submodule update --init", { noremap = true, desc = "Git Submodule Init" })
  end,
}
