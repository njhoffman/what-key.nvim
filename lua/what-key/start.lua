local Keys = require('what-key.keys')
local Util = require('what-key.util')
local Logger = require('what-key.logger')
local Mapper = require('what-key.mapper')
local state = require('what-key.state')

local M = {}

function M.start(keys, opts)
  if state.disabled then
    return
  end
  opts = opts or {}
  if type(opts) == 'string' then
    opts = { mode = opts }
  end

  keys = keys or ''
  -- format last key
  opts.buf = opts.buf or vim.api.nvim_get_current_buf()
  opts.mode = opts.mode or Util.get_mode()
  opts._start_type = opts._start_type and opts._start_type or 'key:' .. keys .. ':' .. opts.mode
  opts._start_time = vim.fn.reltime()
  -- Logger.log_counts()
  Mapper.get_mappings(opts.mode, keys, opts.buf)
  --  update only trees related to buf
  Keys.update(opts.buf)
  -- Logger.log_counts()
  -- start key monitoring loop
  require('what-key.view').on_keys(keys, opts)
end

-- start manually with optional keys and mode parameters
function M.start_command(keys, mode)
  keys = keys or ''
  keys = (keys == '""' or keys == "''") and '' or keys
  mode = (mode == '""' or mode == "''") and '' or mode
  mode = mode or 'n'
  keys = Util.t(keys)
  if not Util.check_mode(mode) then
    Logger.error(
      'Invalid mode passed to :WhichKey (Dont create any keymappings to trigger WhichKey. WhichKey does this automaytically)'
    )
  else
    M.start(keys, { mode = mode, auto = true, _start_type = 'cmd:' .. keys .. ':' .. mode })
  end
end

function M.toggle_background()
  M.start('', { mode = 'n', auto = true, background = true, _start_type = 'background' })
end

return M
