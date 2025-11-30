local M = {}

---@alias Placement "center"|"top"|"bottom"|"left"|"right"|"top_left"|"top_right"|"bottom_left"|"bottom_right"
---@alias Border "none"|"single"|"double"|"rounded"|"solid"|"shadow"

---@class WindowOptions
---@field placement Placement
---@field width number
---@field height number
---@field win_width number
---@field win_height number
---@field padding number?

---@param opts WindowOptions
local function get_window_position(opts)
	local padding = opts.padding or 0
	local row = opts.height - opts.win_height
	local col = opts.width - opts.win_width

	local positions = {
		center = {
			row = math.floor((opts.height - opts.win_height) / 2),
			col = math.floor((opts.width - opts.win_width) / 2),
		},

		top_left = {
			row = padding,
			col = padding,
		},
		top_right = {
			row = padding,
			col = col - padding,
		},
		bottom_left = {
			row = row - padding,
			col = padding,
		},
		bottom_right = {
			row = row - padding,
			col = col - padding,
		},

		top = {
			row = padding,
			col = math.floor(col / 2),
		},
		bottom = {
			row = row - padding,
			col = math.floor(col / 2),
		},
		left = {
			row = math.floor(row / 2),
			col = padding,
		},
		right = {
			row = math.floor(row / 2),
			col = col - padding,
		},
	}

	return positions[opts.placement]
end

---@param bufnr integer Buffer to display, or 0 for current buffer
---@param placement Placement 
---@param width_resize number % of the win width relative to the editor
---@param height_resize number % of the win height relative to the editor
---@param border Border
---@param title string?
function M.open_floating_window(bufnr, placement, width_resize, height_resize, border, title)
  local pos_opts = { placement = placement }
	-- Get editor dimensions
	pos_opts.width = vim.o.columns
	pos_opts.height = vim.o.lines

	pos_opts.win_width = math.floor(pos_opts.width * width_resize)
	pos_opts.win_height = math.floor(pos_opts.height * height_resize)

	local pos = get_window_position(pos_opts)

	local opts = {
		relative = "editor",
		width = pos_opts.win_width,
		height = pos_opts.win_height,
		row = pos.row,
		col = pos.col,
		style = "minimal",
		border = border,
    title = title,
    title_pos = 'center',
	}

	local win = vim.api.nvim_open_win(bufnr, true, opts)
	return win
end

return M
