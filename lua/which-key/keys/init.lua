local Config = require('which-key.config')
local Logger = require('which-key.logger')
local Mapper = require('which-key.mapper')
local Hooks = require('which-key.keys.hooks')
local state = require('which-key.keys.state')

---@class Keys
local M = {}

function M.register(mappings, opts)
  opts = opts or {}

  local parsed_maps = Mapper.parse(mappings, opts)

  -- always create the root node for the mode, even if there's no mappings,
  -- to ensure we have at least a trigger hooked for non documented keymaps
  local modes = {}

  for _, mapping in pairs(parsed_maps) do
    if not modes[mapping.mode] then
      modes[mapping.mode] = true
      Mapper.get_tree(mapping.mode)
    end
    if mapping.cmd ~= nil then
      vim.dbglog('**** NO MAPPING *****', mapping)
      -- Mapper.map(mapping.mode, mapping.prefix, mapping.cmd, mapping.buf, mapping.opts)
    end
    Mapper.get_tree(mapping.mode, mapping.buf).tree:add(mapping)
  end
end

function M.update(buf)
  for k, tree in pairs(state.mappings) do
    if tree.buf and not vim.api.nvim_buf_is_valid(tree.buf) then
      -- vim.dbglog('keys rm update: ' .. tree.buf)
      -- remove group for invalid buffers
      state.mappings[k] = nil
    elseif not buf or not tree.buf or buf == tree.buf then
      -- only update buffer maps, if:
      -- 1. we dont pass a buffer
      -- 2. this is a global node
      -- 3. this is a local buffer node for the passed buffer
      Mapper.update_keymaps(tree.mode, tree.buf)
      Hooks.add_hooks(tree.mode, tree.buf, tree.tree.root)
    end
  end
end

function M.setup()
  for _, t in pairs(Config.options.triggers_nowait) do
    state.nowait[t] = true
  end

  local op_mappings = {}
  for op, label in pairs(Config.options.operators) do
    state.operators[op] = true
    op_mappings[op] = { name = label }
  end

  M.register(op_mappings, { mode = 'v', preset = 'operators' })

  for mode, blacklist in pairs(Config.options.triggers_blacklist) do
    for _, prefix_n in ipairs(blacklist) do
      state.blacklist[mode] = state.blacklist[mode] or {}
      state.blacklist[mode][prefix_n] = true
    end
  end
end

return M
