local Keys = require('which-key.keys')
local Logger = require('which-key.logger')
local state = require('which-key.state')
local start_cmds = require('which-key.start')
local aucommands = require('which-key.aucommands')

---@class WhichKey
local M = {}
M.start = start_cmds.start
M.start_command = start_cmds.start_command
M.toggle_background = start_cmds.toggle_background

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
  -- require('which-key.onkey').setup()
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
