require("config.core.set")
require("config.core.remap")

vim.env.PYENV_VERSION = vim.fn.system('pyenv version'):match('(%S+)%s+%(.-%)')

vim.api.nvim_set_hl(0, 'LineNr', { fg = "white" })

