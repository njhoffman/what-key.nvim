local Config = require('which-key.config')
local Logger = require('which-key.logger')
local Tree = require('which-key.tree')
local Util = require('which-key.util')
local Hooks = require('which-key.keys.hooks')
local operators = require('which-key.keys.operators')
local mapper_utils = require('which-key.mapper.utils')
local state = require('which-key.keys.state')

-- magic description string prefix for nvim-native keybindings to display as groups: keys = { { "<leader>g",  desc = "WhichKeyGroup:git" } }
local secret_group = '^WhichKeyGroup:'

local M = {}

M.dump = mapper_utils.dump
M.get_counts = function()
  return mapper_utils.dump().counts
end

local function lookup(...)
  local ret = {}
  for _, t in ipairs({ ... }) do
    for _, v in ipairs(t) do
      ret[v] = v
    end
  end
  return ret
end

local mapargs = {
  'noremap',
  'desc',
  'expr',
  'silent',
  'nowait',
  'script',
  'unique',
  'callback',
  'replace_keycodes', -- TODO: add config setting for default value
}
local wkargs = {
  'prefix',
  'mode',
  'plugin',
  'buffer',
  'remap',
  'cmd',
  'name',
  'group',
  'group_type',
  'children',
  'preset',
  'cond',
}
local transargs = lookup({
  'noremap',
  'expr',
  'silent',
  'nowait',
  'script',
  'unique',
  'prefix',
  'mode',
  'buffer',
  'preset',
  'replace_keycodes',
})
local args = lookup(mapargs, wkargs)

function M.child_opts(opts)
  local ret = {}
  for k, v in pairs(opts) do
    if transargs[k] then
      ret[k] = v
    end
  end
  return ret
end

function M._process(value, opts)
  local list = {}
  local children = {}
  for k, v in pairs(value) do
    if type(k) == 'number' then
      if type(v) == 'table' then
        -- nested child, without key
        table.insert(children, v)
      else
        -- list value
        table.insert(list, v)
      end
    elseif args[k] then
      -- option
      opts[k] = v
    else
      -- nested child, with key
      children[k] = v
    end
  end
  return list, children
end

function M._parse(value, mappings, opts)
  if type(value) ~= 'table' then
    value = { value }
  end

  local list, children = M._process(value, opts)

  if opts.plugin then
    opts.group = true
  end

  if opts.name then
    opts.name = opts.name and opts.name:gsub('^%+', '')
    opts.group = true
  end

  -- fix remap
  if opts.remap then
    opts.noremap = not opts.remap
    opts.remap = nil
  end

  -- fix buffer
  if opts.buffer == 0 then
    opts.buffer = vim.api.nvim_get_current_buf()
  end

  if opts.cond ~= nil then
    if type(opts.cond) == 'function' then
      if not opts.cond() then
        return
      end
    elseif not opts.cond then
      return
    end
  end

  -- process any array child mappings
  for k, v in pairs(children) do
    local o = M.child_opts(opts)
    if type(k) == 'string' then
      o.prefix = (o.prefix or '') .. k
    end
    M._try_parse(v, mappings, o)
  end

  -- { desc }
  if #list == 1 then
    if type(list[1]) ~= 'string' then
      error('Invalid mapping for ' .. vim.inspect({ value = value, opts = opts }))
    end
    opts.desc = list[1]
  -- { cmd, desc }
  elseif #list == 2 then
    -- desc
    assert(type(list[2]) == 'string')
    opts.desc = list[2]

    -- cmd
    if type(list[1]) == 'string' then
      opts.cmd = list[1]
    elseif type(list[1]) == 'function' then
      opts.cmd = ''
      opts.callback = list[1]
    else
      error('Incorrect mapping ' .. vim.inspect(list))
    end
  elseif #list > 2 then
    error('Incorrect mapping ' .. vim.inspect(list))
  end

  vim.dbglog('opts', opts)
  if opts.desc or opts.group then
    if type(opts.mode) == 'table' then
      for _, mode in pairs(opts.mode) do
        local mode_opts = vim.deepcopy(opts)
        mode_opts.mode = mode
        table.insert(mappings, mode_opts)
      end
    else
      table.insert(mappings, opts)
    end
  end
end

---@return Mapping
function M.to_mapping(mapping)
  mapping.silent = mapping.silent ~= false
  mapping.noremap = mapping.noremap ~= false
  if mapping.cmd and mapping.cmd:lower():find('^<plug>') then
    mapping.noremap = false
  end

  mapping.buf = mapping.buffer
  mapping.buffer = nil

  mapping.mode = mapping.mode or 'n'
  mapping.label = mapping.desc or mapping.name
  mapping.keys = Util.parse_keys(mapping.prefix or '')

  local opts = {}
  for _, o in ipairs(mapargs) do
    opts[o] = mapping[o]
    mapping[o] = nil
  end
  mapping.opts = opts
  return mapping
end

function M._try_parse(value, mappings, opts)
  local ok, err = pcall(M._parse, value, mappings, opts)
  if not ok then
    Logger.error(err)
  end
end

---@return Mapping[]
function M.parse(mappings, opts)
  opts = opts or {}
  local ret = {}
  M._try_parse(mappings, ret, opts)
  return vim.tbl_map(function(m)
    return M.to_mapping(m)
  end, ret)
end

---@param mode string
---@param buf? buffer
function M.get_tree(mode, buf)
  mode = mode:sub(1, 1)
  if mode == 's' or mode == 'x' then
    mode = 'v'
  end
  Util.check_mode(mode, buf)
  local idx = mode .. (buf and tostring(buf) or '')
  if not state.mappings[idx] then
    state.mappings[idx] = { mode = mode, buf = buf, tree = Tree:new() }
  end
  return state.mappings[idx]
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

  -- vim.dbglog(
  --   mode .. ' ' .. (buf and buf or '') .. ' updating ' .. #vim.tbl_keys(keymaps),
  --   ' mapper keymaps'
  -- )
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
      local cmd_desc = keymap.rhs
      local unparsed_cmds = {}
      if type(keymap.callback) == 'function' and not keymap.rhs then
        cmd_desc = mapper_utils.get_anon_function(debug.getinfo(keymap.callback))
        if not string.find(cmd_desc, '%)$') then
          table.insert(unparsed_cmds, { cmd_desc, keymap })
          cmd_desc = '(anon)'
        end
      end

      local mapping = {
        prefix = keymap.lhs,
        keys = keys,
        cmd = keymap.rhs,
        desc = keymap.desc,
        callback = keymap.callback,
      }
      mapping.label = mapping.desc or cmd_desc or ''
      if is_group then
        mapping.group = true
        mapping.group_type = not keymap.callback and not keymap.rhs and not cmd_desc and 'prefix'
          or 'multi'
      end

      local node = tree:add(mapping)
    end
  end
end

---@return MappingGroup
function M.get_mappings(mode, prefix_i, buf)
  ---@class MappingGroup
  ---@field mode string
  ---@field prefix_i string
  ---@field buf number
  ---@field mapping? Mapping
  ---@field mappings VisualMapping[]
  -- vim.dbglog('get mappings: ' .. mode .. ' ' .. prefix_i .. ' ' .. (buf or ''))
  local ret = { mapping = nil, mappings = {}, mode = mode, buf = buf, prefix_i = prefix_i }

  local prefix_len = #Util.parse_internal(prefix_i)

  ---@param node? Node
  local function add(node)
    if node then
      if node.mapping then
        ret.mapping = vim.tbl_deep_extend('force', {}, ret.mapping or {}, node.mapping)
      end
      for k, child in pairs(node.children) do
        if
          child.mapping
          and child.mapping.label ~= 'which_key_ignore'
          and child.mapping.desc ~= 'which_key_ignore'
        then
          ret.mappings[k] = vim.tbl_deep_extend('force', {}, ret.mappings[k] or {}, child.mapping)
        end
      end
    end
  end

  local plugin_context = { buf = buf, mode = mode }
  add(M.get_tree(mode).tree:get(prefix_i, nil, plugin_context))
  add(M.get_tree(mode, buf).tree:get(prefix_i, nil, plugin_context))

  -- Handle motions
  operators.process_motions(ret, mode, prefix_i, buf)

  -- Fix labels
  local tmp_mappings = {}
  for _, value in pairs(ret.mappings) do
    value.key = value.keys.notation[prefix_len + 1]
    if Config.options.key_labels[value.key] then
      value.key = Config.options.key_labels[value.key]
    end
    local skip = false
    if not value.label or value.desc then
      if value.group and Config.options.ignore_unnamed_groups then
        skip = true
      elseif not value.group and Config.options.ignore_missing_desc == true then
        skip = true
      end
    end
    if Util.t(value.key) == Util.t('<esc>') then
      skip = true
    end
    if not skip then
      if type(value.value) == 'string' then
        value.value = vim.fn.strtrans(value.value) or value.value
      end
      local submap = M.get_tree(mode).tree:get(value.keys.keys, nil, plugin_context)
      local submap_buf = M.get_tree(mode, buf).tree:get(value.keys.keys, nil, plugin_context)

      local op_children = {}
      local op_i, op_n = operators.get_operator(value.prefix)
      if op_n == value.prefix then
        value.op_i = op_i
        value.group = true
        value.group_type = 'operator'
        local op_results = M.get_mappings(mode, op_i, buf)
        for _, mapping in pairs(op_results.mappings) do
          table.insert(op_children, mapping.prefix)
        end
      end

      local children = vim.tbl_deep_extend(
        'force',
        {},
        vim.tbl_keys(submap and submap.children or {}),
        vim.tbl_keys(submap_buf and submap_buf.children or {}),
        vim.tbl_keys(op_children)
      )
      if #vim.tbl_keys(children) > 0 then
        value.group = true
        value.group_type = 'multi'
        value.children = #vim.tbl_keys(children)
      end

      if value.group then
        value.label = value.label or value.desc or value.cmd or '+prefix'
        value.label = value.label:gsub('^%+', '')
        value.label = Config.options.icons.group .. value.label
      elseif not value.label then
        value.label = value.desc or value.cmd or ''
        for _, v in ipairs(Config.options.hidden) do
          value.label = value.label:gsub(v, '')
        end
      end

      -- remove duplicated keymap
      local exists = false
      for k, v in pairs(tmp_mappings) do
        if type(v) == 'table' and v.key == value.key then
          tmp_mappings[k] = value
          exists = true
          break
        end
      end
      if not exists then
        table.insert(tmp_mappings, value)
      end
    end
  end

  -- Sort items, but not for plugins
  table.sort(tmp_mappings, function(a, b)
    if a.order and b.order then
      return a.order < b.order
    end
    if a.group == b.group then
      local ak = (a.key or ''):lower()
      local bk = (b.key or ''):lower()
      local aw = ak:match('[a-z]') and 1 or 0
      local bw = bk:match('[a-z]') and 1 or 0
      if aw == bw then
        return ak < bk
      end
      return aw < bw
    else
      return (a.group and 1 or 0) < (b.group and 1 or 0)
    end
  end)
  ret.mappings = tmp_mappings

  -- vim.dbglog('returning  ' .. #ret.mappings .. ' mappings')
  return ret
end
return M
