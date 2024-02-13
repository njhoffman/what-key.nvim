local Config = require('which-key.config')
local Mapper = require('which-key.mapper')
local Hooks = require('which-key.keys.hooks')
local state = require('which-key.keys.state')

---@class Keys
local M = {}

function M.register(mappings, opts)
  opts = opts or {}

  mappings = Mapper.parse(mappings, opts)

  -- always create the root node for the mode, even if there's no mappings,
  -- to ensure we have at least a trigger hooked for non documented keymaps
  local modes = {}

  for _, mapping in pairs(mappings) do
    if not modes[mapping.mode] then
      modes[mapping.mode] = true
      Mapper.get_tree(mapping.mode)
    end
    if mapping.cmd ~= nil then
      Mapper.map(mapping.mode, mapping.prefix, mapping.cmd, mapping.buf, mapping.opts)
    end
    Mapper.get_tree(mapping.mode, mapping.buf).tree:add(mapping)
  end
end

function M.update(buf)
  for k, tree in pairs(state.mappings) do
    if tree.buf and not vim.api.nvim_buf_is_valid(tree.buf) then
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
  -- 0.0324  367 (n:306 o:57 v:2)
  -- local builtin_ops = require('which-key.plugins.presets').operators
  local builtin_ops = require('which-key.presets').presets.operators
  for op, _ in pairs(builtin_ops) do
    state.operators[op] = true
  end
  local mappings = {}
  for op, label in pairs(Config.options.operators) do
    state.operators[op] = true
    if builtin_ops[op] then
      mappings[op] = { name = label }
    end
  end
  for _, t in pairs(Config.options.triggers_nowait) do
    state.nowait[t] = true
  end

  M.register(mappings, { mode = 'n', preset = 'operators' })
  M.register({ i = { name = 'inside' }, a = { name = 'around' } }, { mode = 'v', preset = 'text_objects' })

  for mode, blacklist in pairs(Config.options.triggers_blacklist) do
    for _, prefix_n in ipairs(blacklist) do
      state.blacklist[mode] = state.blacklist[mode] or {}
      state.blacklist[mode][prefix_n] = true
    end
  end
end

return M
