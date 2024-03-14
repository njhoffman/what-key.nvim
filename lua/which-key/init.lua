local Keys = require('which-key.keys')
local Util = require('which-key.util')
local Logger = require('which-key.logger')
local Mapper = require('which-key.mapper')
local state = require('which-key.state')
local aucommands = require('which-key.aucommands')

---@class WhichKey
local M = {}

local function schedule_load()
  if state.scheduled then
    return
  end
  state.scheduled = true
  if vim.v.vim_did_enter == 0 then
    aucommands.schedule_load()
  else
    M.load()
  end
end

---@param options? Options
function M.setup(options)
  if not state.disabled then
    require('which-key.config').setup(options)
    schedule_load()
  end
end

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
  Logger.log_counts()
  Mapper.get_mappings(opts.mode, keys, opts.buf)
  -- -- update only trees related to buf
  Keys.update(opts.buf)
  Logger.log_counts()
  -- trigger which key
  require('which-key.view').start(keys, opts)
end

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

-- Defer registering keymaps until VimEnter
function M.register(mappings, opts)
  -- -- Fixes a bug, where the WhichKey window doesn’t show up in the visual mode.
  --     -- The open bug in question: https://github.com/folke/which-key.nvim/issues/458.
  --     if mode == "v" or mode == "x" then
  --       vim.keymap.set(mode, keymap, "<cmd>WhichKey " .. keymap .. " " .. mode .. "<cr>")
  --     end
  schedule_load()
  if not opts or type(opts.mode) == 'nil' then
    Logger.info('No mode passed to register: ' .. vim.inspect(mappings, opts))
  else
    local modes = type(opts.mode) == 'string' and { opts.mode } or opts.mode
    for _, mode in pairs(modes) do
      opts.mode = mode
      table.insert(state.queue, { mappings, opts })
    end
  end
end

-- Load mappings and update only once
function M.load(vim_enter)
  if state.loaded then
    return
  end
  state.load_start = vim.fn.reltime()
  -- require('which-key.plugins').setup()
  require('which-key.presets').setup()
  require('which-key.colors').setup()
  aucommands.setup()
  require('which-key.onkey').setup()
  Keys.register({}, { prefix = '<leader>', mode = 'n' })
  Keys.register({}, { prefix = '<leader>', mode = 'v' })
  Keys.setup()
  aucommands.register_queue(true)
  state.loaded = true
end

function M.reset()
  -- local mappings = Keys.mappings
  require('plenary.reload').reload_module('which-key')
  -- require("which-key.Keys").mappings = mappings
  require('which-key').setup()
end

return M
