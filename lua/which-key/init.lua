local Keys = require('which-key.keys')
local Util = require('which-key.util')
local Logger = require('which-key.logger')
local Mapper = require('which-key.mapper')
local hooks = require('which-key.keys.hooks')

---@class WhichKey
local M = {}

local disabled = false
local loaded = false -- once we loaded everything
local scheduled = false
local load_start = nil

local function schedule_load()
  if scheduled then
    return
  end
  scheduled = true
  if vim.v.vim_did_enter == 0 then
    -- vim.cmd([[au VimEnter * ++once lua require("which-key").load()]])
    vim.api.nvim_create_autocmd('VimEnter', {
      group = 'WhichKey',
      once = true,
      command = 'lua vim.defer_fn(require("which-key").load, 100)',
    })
  else
    M.load()
  end
end

---@param options? Options
function M.setup(options)
  if not disabled then
    load_start = vim.fn.reltime()
    require('which-key.config').setup(options)
    vim.api.nvim_create_augroup('WhichKey', { clear = true })
    schedule_load()
  end
end

function M.start(keys, opts)
  if disabled then
    return
  end
  opts = opts or {}
  if type(opts) == 'string' then
    opts = { mode = opts }
  end

  keys = keys or ''
  -- format last key
  opts.mode = opts.mode or Util.get_mode()
  opts._start_type = opts._start_type and opts._start_type or 'key:' .. keys .. ':' .. opts.mode
  opts._start_time = vim.fn.reltime()

  local buf = vim.api.nvim_get_current_buf()
  -- make sure the trees exist for update
  Mapper.get_tree(opts.mode)
  Mapper.get_tree(opts.mode, buf)
  -- update only trees related to buf
  Keys.update(buf)
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

local queue = {}

-- Defer registering keymaps until VimEnter
function M.register(mappings, opts)
  schedule_load()
  if not opts or type(opts.mode) == 'nil' then
    Logger.info('No mode passed to register: ' .. vim.inspect(mappings, opts))
  elseif loaded then
    Keys.register(mappings, opts)
    Keys.update()
  else
    table.insert(queue, { mappings, opts })
  end
end

-- Load mappings and update only once
function M.load(vim_enter)
  if loaded then
    return
  end
  require('which-key.plugins').setup()
  require('which-key.presets').setup()
  require('which-key.colors').setup()
  -- require('which-key.onkey').setup()
  Keys.setup()
  Keys.register({}, { prefix = '<leader>', mode = 'n' })
  Keys.register({}, { prefix = '<leader>', mode = 'v' })

  for _, reg in pairs(queue) do
    local opts = reg[2] or {}
    opts.update = false
    Keys.register(reg[1], opts)
  end

  Keys.update()
  Logger.log_startup(load_start)
  queue = {}
  loaded = true
end

function M.reset()
  -- local mappings = Keys.mappings
  require('plenary.reload').reload_module('which-key')
  -- require("which-key.Keys").mappings = mappings
  require('which-key').setup()
end

return M
