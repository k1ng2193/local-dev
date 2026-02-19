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

---@class WindowConfig
---@field placement Placement?
---@field width_resize number? % of the win width relative to the editor
---@field height_resize number? % of the win height relative to the editor
---@field border Border?
---@field title string?

---@param bufnr integer Buffer to display, or 0 for current buffer
---@param cfg WindowConfig
function M.open_floating_window(bufnr, cfg)
  local placement = cfg.placement or "right"
  local width_resize = cfg.width_resize or 0.3
  local height_resize = cfg.height_resize or 1
  local border = cfg.border or "single"

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
    title = cfg.title,
    title_pos = 'center',
	}

	local win = vim.api.nvim_open_win(bufnr, false, opts)
	return win
end

return M
