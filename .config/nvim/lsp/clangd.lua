return {
	cmd = {
    "clangd",
		"--background-index",
    "--modules",
		"--suggest-missing-includes",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--enable-config",
	},
	filetypes = { "c", "cpp", "objc", "objcpp", "h", "m", "mm" },
	root_markers = { "compile_commands.json", ".clangd", ".git" },
	settings = {
		compilationDatabasePath = "build",
		fallbackFlags = { "-std=c++17", "-Wall" },
	},
}
