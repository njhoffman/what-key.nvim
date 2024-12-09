local Config = require('which-key.config')
local Logger = require('which-key.logger')
local Tree = require('which-key.tree')
local Util = require('which-key.util')
local Hooks = require('which-key.keys.hooks')
local operators = require('which-key.keys.operators')
local mapper_parser = require('which-key.mapper.parser')
local mapper_utils = require('which-key.mapper.utils')
local state = require('which-key.keys.state')

-- magic description string prefix for nvim-native keybindings to display as groups: keys = { { "<leader>g",  desc = "WhichKeyGroup:git" } }
local secret_group = '^WhichKeyGroup:'

local M = {}

M.parse = mapper_parser.parse
M.dump = mapper_utils.dump
M.get_counts = function()
  return mapper_utils.dump().counts
end

---@param mode string
---@param buf? buffer
function M.get_tree(mode, buf)
  if mode == 's' or mode == 'x' then
    mode = 'v'
  elseif mode == 'no' then
    mode = 'n'
  end
  Util.check_mode(mode, buf)
  local idx = mode .. (buf and tostring(buf) or '')
  if not state.mappings[idx] then
    state.mappings[idx] = { mode = mode, buf = buf, tree = Tree:new() }
  end
  return state.mappings[idx]
end

function M.get_desc(keymap)
  local desc = keymap.desc or keymap.rhs or ''
  if type(keymap.callback) == 'function' and #desc == 0 then
    desc = mapper_utils.get_anon_function(debug.getinfo(keymap.callback))
    if not string.find(desc, '%)$') then
      -- table.insert(unparsed, { cmd_desc, keymap })
      desc = '(anon)'
    end
  end
  return desc
end

---Called from keys.update()
---@param mode string
---@param buf number
function M.update_keymaps(mode, buf)
  ---@type Keymap[]
  local keymaps = buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
  local tree = M.get_tree(mode, buf).tree

  local function is_nop(keymap)
    return not keymap.callback and (keymap.rhs == '' or keymap.rhs:lower() == '<nop>')
  end

  for _, keymap in pairs(keymaps) do
    local is_group = false
    local skip = false

    if is_nop(keymap) then
      skip = true
    end
    skip = Hooks.is_hook(keymap.lhs, keymap.rhs)

    -- Magic identifier for keygroups in regular keybindings
    if keymap.desc and keymap.desc:find(secret_group) then
      keymap.desc = keymap.desc:gsub(secret_group, '')
      is_group = true
      skip = false
    end

    -- check for ignored items in configuration
    for _, v in ipairs(Config.options.ignored) do
      if keymap.lhs == v or keymap.lhs:find(v) then
        skip = true
        break
      end
    end

    local keys = Util.parse_keys(keymap.lhs)
    -- don't include Plug keymaps
    if string.find(keys.notation[1]:lower(), '<plug>') then
      skip = true
    end

    if not skip then
      local mapping = {
        prefix = keymap.lhs,
        keys = keys,
        cmd = keymap.rhs,
        callback = keymap.callback,
        mode = keymap.mode,
        label = M.get_desc(keymap),
      }

      local node = tree:add(mapping)
      if node and node.mapping and node.mapping.label == '' and mapping.label ~= '' then
        node.mapping.label = mapping.label
      end

      if is_group then
        mapping.group = not keymap.callback and not keymap.rhs and 'prefix' or 'multi'
      end
    end
  end
end

---@return MappingGroup
function M.get_map_group(context, prefix_i)
  local map_group = {
    mapping = nil,
    -- mappings = {}, -- change to children
    children = {}, -- next level of mappings that belong to this keymap
    mode = context.mode, -- calculated mode from initial mode or mappings
    buf = context.buf, -- source buffer where keys were entered
    prefix_i = prefix_i, -- raw keys entered
    prefix_n = Util.t(prefix_i), -- raw keys entered
  }

  ---@param node? Node
  local function add_mapping(node)
    if node then
      if node.mapping then
        map_group.mapping = vim.tbl_deep_extend('force', {}, map_group.mapping or {}, node.mapping)
      end
      for k, child in pairs(node.children) do
        if child.mapping and child.mapping.label ~= 'which_key_ignore' then
          map_group.children[k] =
            vim.tbl_deep_extend('force', {}, map_group.children[k] or {}, child.mapping)
        end
      end
    end
  end

  add_mapping(M.get_tree(context.mode).tree:get(prefix_i, nil, context))
  add_mapping(M.get_tree(context.mode, context.buf).tree:get(prefix_i, nil, context))

  -- Handle motions
  operators.process_motions(map_group, context.mode, prefix_i, context.buf)

  return map_group
end

function M.format_child(mapping, mode, context, buf)
  if type(mapping.value) == 'string' then
    mapping.value = vim.fn.strtrans(mapping.value) or mapping.value
  end

  local submap = M.get_tree(mode).tree:get(mapping.keys.raw, nil, context)
  local submap_buf = M.get_tree(mode, buf).tree:get(mapping.keys.raw, nil, context)

  -- check if child mapping is an operator
  local op_children = {}
  local op_i, op_n, op_desc = operators.get_operator(mapping.prefix)
  if op_n == mapping.prefix and mode == 'n' then
    mapping.type = 'operator'
    mapping.label = op_desc
    local op_results = M.get_mappings(mode, op_i, buf)
    for _, mapping in pairs(op_results.children) do
      table.insert(op_children, mapping.prefix)
    end
  end

  -- calculate total number of children this mapping has
  local children = vim.tbl_deep_extend(
    'force',
    {},
    vim.tbl_keys(submap and submap.children or {}),
    vim.tbl_keys(submap_buf and submap_buf.children or {}),
    vim.tbl_keys(op_children)
  )

  if #vim.tbl_keys(children) > 0 then
    mapping.group = mapping.group or 'multi'
    mapping.child_count = #vim.tbl_keys(children)
  end
  -- if mapping.child_count == 4 then
  --   vim.dbglog('**', submap.children or {}, submap_buf.children or {})
  -- end

  -- final description label formatting
  local label = mapping.label --[[ mapping.opts.desc or ]]
    or mapping.cmd
    or nil
  if mapping.group then
    mapping.label = label or '+prefix'
    mapping.label = mapping.label:gsub('^%+', '')
    mapping.label = Config.options.icons.group .. mapping.label
  else
    mapping.label = label or ''
    for _, v in ipairs(Config.options.hidden) do
      mapping.label = mapping.label:gsub(v, '')
    end
  end
end

-- called from user command, recursively, and from operators
function M.get_mappings(mode, prefix_i, buf)
  local context = { buf = buf, mode = mode }
  local map_group = M.get_map_group(context, prefix_i)

  -- Format keys, labels and determine if skipping based on configuration
  local tmp_mappings = {}
  for _, mapping in pairs(map_group.children) do
    mapping.key = mapping.keys.notation[#mapping.keys.notation]
    if Config.options.key_labels[mapping.key] then
      mapping.key = Config.options.key_labels[mapping.key]
    end

    local skip = Util.t(mapping.key) == Util.t('<esc>')
    if not mapping.label then
      if mapping.group and Config.options.ignore_unnamed_groups then
        skip = true
      elseif not mapping.group and Config.options.ignore_missing_desc == true then
        skip = true
      end
    end

    if not skip then
      M.format_child(mapping, mode, context, buf)

      -- remove duplicated keymap
      local exists = false
      for k, v in pairs(tmp_mappings) do
        if type(v) == 'table' and v.key == mapping.key then
          tmp_mappings[k] = mapping
          exists = true
          break
        end
      end
      if not exists then
        table.insert(tmp_mappings, mapping)
      end
    end
  end

  -- todo: extract into a hook
  table.sort(tmp_mappings, function(a, b)
    if a.order and b.order then
      return a.order < b.order
    elseif a.group and not b.group or (not a.group and b.group) then
      return a.group and not b.group
    elseif type(a.children) ~= type(b.children) then
      return type(a.children) == 'number'
    elseif #a.key ~= #b.key then
      return #a.key < #b.key
    else
      local ak = (a.key or ''):lower()
      local bk = (b.key or ''):lower()
      local aw = ak:match('[a-z]') and 1 or 0
      local bw = bk:match('[a-z]') and 1 or 0
      if aw == bw then
        if ak == bk then
          return b.key < a.key
        else
          return ak < bk
        end
      end
      return aw < bw
    end
  end)

  map_group.children = tmp_mappings

  -- if map_group.op_i then
  -- vim.dbglog('returning  ' .. #map_group.children .. ' children')
  -- vim.dbglog()
  -- vim.dbglog(require('which-key.util').without(map_group, 'children'))

  -- end
  return map_group
end

return M
