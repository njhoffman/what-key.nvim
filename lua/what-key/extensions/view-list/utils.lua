local Config = require('what-key.config')

local state = require('what-key.extensions.view-list.state')

local M = {}

function M.set_cursor(cursor_row)
  state.cursor.row = cursor_row
  vim.api.nvim_win_set_cursor(state.win, { cursor_row, 1 })
end

function M.show_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_add_highlight(
    buf,
    Config.namespace,
    'Cursor',
    cursor[1] - 1,
    cursor[2],
    cursor[2] + 1
  )
end

function M.get_bounds(opts)
  opts = opts or Config.options.layout
  return {
    width = {
      max = type(opts.width.max) == 'function' and opts.width.max() or opts.width.max,
      min = type(opts.width.min) == 'function' and opts.width.min() or opts.width.min,
    },
    height = {
      max = type(opts.height.max) == 'function' and opts.height.max() or opts.height.max,
      min = type(opts.height.min) == 'function' and opts.height.min() or opts.height.min,
    },
  }
end

function M.get_canvas_width()
  local win_width = vim.api.nvim_win_get_width(state.win)
  local canvas_width = win_width
    - Config.options.window.padding[2]
    - Config.options.window.padding[4]
  return canvas_width
end

function M.hide_cursor()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, Config.namespace, 0, -1)
end

function M.is_enabled(buf)
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
  for _, bt in ipairs(Config.options.disable.buftypes) do
    if bt == buftype then
      return false
    end
  end

  local filetype = vim.api.nvim_get_option_value('filetype', { buf = buf })
  for _, bt in ipairs(Config.options.disable.filetypes) do
    if bt == filetype then
      return false
    end
  end
  return true
end

function M.is_valid(buf, win)
  return buf
    and win
    and vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_buf_is_loaded(buf)
    and vim.api.nvim_win_is_valid(win)
end

return M
