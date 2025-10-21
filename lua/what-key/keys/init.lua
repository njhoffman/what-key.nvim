local Config = require("what-key.config")
local Logger = require("what-key.logger")
local Mapper = require("what-key.mapper")
local Hooks = require("what-key.keys.hooks")
local state = require("what-key.keys.state")

---@class Keys
local M = {}

function M.register(mappings, opts)
  opts = opts or {}

  -- vim.dbglog(mappings, #mappings)
  local parsed_maps = Mapper.parse(mappings, opts)
  if #mappings == 1 then
    -- vim.dbglog("register", mappings, parsed_maps)
  end

  -- always create the root node for the mode, even if there's no mappings,
  -- to ensure we have at least a trigger hooked for non documented keymaps
  local modes = {}

  for _, mapping in pairs(parsed_maps) do
    if not modes[mapping.mode] then
      modes[mapping.mode] = true
      Mapper.get_tree(mapping.mode)
    end
    if mapping.cmd ~= nil then
      -- vim.dbglog("**** NO MAPPING *****", mapping)
      -- Mapper.map(mapping.mode, mapping.prefix, mapping.cmd, mapping.buf, mapping.opts)
    end
    Mapper.get_tree(mapping.mode, mapping.buf).tree:add(mapping)
  end
end

function M.update(buf, first_load)
  -- only update buffer maps, if:
  -- 1. we dont pass a buffer
  -- 2. this is a global node
  -- 3. this is a local buffer node for the passed buffer
  for k, tree in pairs(state.mappings) do
    if tree.buf and not vim.api.nvim_buf_is_valid(tree.buf) then
      -- remove group for invalid buffers
      -- vim.dbglog("update 0", tree.buf, buf, first_load)
      state.mappings[k] = nil
    elseif buf and tree.buf and tree.buf == buf then
      -- vim.dbglog("update 1", tree.mode, tree.buf, buf, first_load)
      Mapper.update_keymaps(tree.mode, tree.buf, first_load)
      Hooks.add_hooks(tree.mode, tree.buf, tree.tree.root)
    elseif (tree.buf == nil or tree.buf == 0) and (buf == nil or buf == 0) then
      -- vim.dbglog("update 2", tree.mode, tree.buf, buf, first_load)
      Mapper.update_keymaps(tree.mode, tree.buf, first_load)
      Hooks.add_hooks(tree.mode, tree.buf, tree.tree.root)
    end
  end
end

function M.setup()
  for _, t in pairs(Config.options.triggers_nowait) do
    state.nowait[t] = true
  end
  -- M.register({
  --   ["<F19>"] = { "normal mode keymap root", { mode = "n" } },
  -- }, { silent = true, remap = false })

  -- M.register({
  --   ["<F19>"] = { "insert mode keymap root", { mode = "i" } },
  -- }, { silent = true, remap = false })

  local op_mappings = {}
  for op, label in pairs(Config.options.operators) do
    state.operators[op] = true
    op_mappings[op] = { name = label }
  end

  M.register(op_mappings, { mode = "v", preset = "operators" })

  for mode, blacklist in pairs(Config.options.triggers_blacklist) do
    for _, prefix_n in ipairs(blacklist) do
      state.blacklist[mode] = state.blacklist[mode] or {}
      state.blacklist[mode][prefix_n] = true
    end
  end
end

return M
