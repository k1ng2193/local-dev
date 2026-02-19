local utils = require("core.utils")

return {
  cmd = { "ty" },
  root_dir = function(bufnr, on_dir)
    utils.find_lsp_root_dir(bufnr, on_dir, { "uv.lock", ".venv" })
  end,
  root_markers = { "pyproject.toml", "requirements.txt", ".git" },
}
