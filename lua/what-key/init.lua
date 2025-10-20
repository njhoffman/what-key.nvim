local Keys = require("what-key.keys")
local Logger = require("what-key.logger")
local state = require("what-key.state")
local start_cmds = require("what-key.start")
local aucommands = require("what-key.aucommands")

---@class WhatKey
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
    require("what-key.config").setup(options)
    schedule_load()
  end
end

-- Defer registering keymaps until VimEnter
function M.register(mappings, opts)
  -- -- Fixes a bug, where the WhatKey window doesn’t show up in the visual mode.
  --     -- The open bug in question: https://github.com/folke/What-key.nvim/issues/458.
  --     if mode == "v" or mode == "x" then
  --       vim.keymap.set(mode, keymap, "<cmd>WhatKey " .. keymap .. " " .. mode .. "<cr>")
  --     end
  if not opts or type(opts.mode) == "nil" then
    for _, mapping in pairs(mappings) do
      if type(mapping.mode) ~= "string" then
        Logger.info("No mode passed to register: " .. vim.inspect(mapping, opts))
      else
        table.insert(state.queue, { mapping, opts })
      end
    end
  else
    local modes = type(opts.mode) == "string" and { opts.mode } or opts.mode
    for _, mode in pairs(modes) do
      opts.mode = mode
      table.insert(state.queue, { mappings, opts })
    end
  end
  schedule_load()
  -- migrate to v2
  -- if opts then
  --   for k, v in pairs(opts) do
  --     mappings[k] = v
  --   end
  -- end
  --
  -- M.add(mappings, { version = 1 })
end

--- Add mappings to What-key
---@param mappings wk.Spec
---@param opts? wk.Parse
local added = {}
function M.add(mappings, opts)
  local to_add = {}
  for _, mapping in ipairs(mappings) do
    local lhs = mapping[1]
    local icon = type(mapping.icon) == "function" and mapping.icon().icon
      or type(mapping.icon) == "string" and mapping.icon
    local desc = type(mapping.desc) == "function" and mapping.desc() or type(mapping.desc) == "string" and mapping.desc
    desc = icon .. " " .. desc
    to_add[1] = { [lhs] = { desc } }
    to_add[2] = { desc = mapping.desc, icon = mapping.icon, mode = mapping.mode }
  end
  table.insert(state.queue, to_add)
  table.insert(added, to_add)
  schedule_load()
  -- table.insert(state.queue, { mappings, opts })
  -- table.insert(state.queue, { spec = mappings, opts = opts })
end

-- Load mappings and update only once
function M.load(vim_enter)
  if state.loaded then
    vim.dbglog("already laoded", #state.queue)
    aucommands.register_queue()
    return
    -- else
  end
  state.load_start = vim.fn.reltime()
  -- require('what-key.plugins').setup()
  require("what-key.presets").setup()
  require("what-key.colors").setup()
  aucommands.setup()
  -- require("what-key.onkey").setup()
  Keys.setup()
  aucommands.register_queue(_, true)
  state.loaded = true
end

function M.reset()
  -- local mappings = Keys.mappings
  require("plenary.reload").reload_module("what-key")
  -- require("what-key.Keys").mappings = mappings
  require("what-key").setup()
end

return M
