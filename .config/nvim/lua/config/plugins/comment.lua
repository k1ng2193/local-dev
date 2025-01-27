return {
	"numToStr/Comment.nvim",
	lazy = false,
	config = function()
    require('Comment').setup()

	  local ft = require('Comment.ft')

	  local jsOpts = {'//%s', '{/*%s*/}'}

	  ft.set('javascriptreact', jsOpts)
    ft.set('typescriptreact', jsOpts)
  end,
}
