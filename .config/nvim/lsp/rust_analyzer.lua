return {
  cmd = { "rust-analyzer" },
  root_markers = { "Cargo.toml" },
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
        extraArgs = { "--no-deps" },
      },
      checkOnSave = true,
      files = {
        watcher = "server",
      },
    },
  },
}
