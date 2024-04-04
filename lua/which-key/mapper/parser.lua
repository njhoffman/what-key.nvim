local Logger = require('which-key.logger')
local Util = require('which-key.util')
local mapper_utils = require('which-key.mapper.utils')

-- keymap fields that will be removed from base table and saved to opts fields
local mapargs = {
  'buffer',
  'callback',
  'desc',
  'expr',
  'noremap',
  'nowait',
  'script',
  'silent',
  'unique',
  'replace_keycodes', -- TODO: add config setting for default value
}

-- whichkey specific metadata fields
local wkargs = {
  'category',
  'children',
  'cmd',
  'cond',
  'group',
  'mode',
  'name',
  'plugin',
  'prefix',
  'preset',
  'remap',
}

local args = mapper_utils.lookup(mapargs, wkargs)

--
local transargs = mapper_utils.lookup({
  'buffer',
  'expr',
  'mode',
  'noremap',
  'nowait',
  'prefix',
  'preset',
  'replace_keycodes',
  'script',
  'silent',
  'unique',
})

local M = {}

function M._child_opts(opts)
  local child_opts = {}
  for k, v in pairs(opts) do
    if transargs[k] then
      child_opts[k] = v
    end
  end
  return child_opts
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

function M._try_parse(value, mappings, opts)
  local ok, err = pcall(M._parse, value, mappings, opts)
  if not ok then
    Logger.error(err)
  end
end

function M._parse(value, mappings, opts)
  if type(value) ~= 'table' then
    value = { value }
  end

  local list, children = M._process(value, opts)

  if opts.name then
    opts.name = opts.name and opts.name:gsub('^%+', '')
    opts.group = 'prefix'
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

  -- don't add if cond is defined and not true
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
    local child_opts = M._child_opts(opts)
    if type(k) == 'string' then
      child_opts.prefix = (child_opts.prefix or '') .. k
    end
    M._try_parse(v, mappings, child_opts)
  end

  -- { desc }
  if #list == 1 then
    if type(list[1]) ~= 'string' then
      error('Invalid mapping for ' .. vim.inspect({ value = value, opts = opts }))
    end
    opts.desc = list[1]
  -- { cmd, desc }
  elseif #list == 2 then
    assert(type(list[2]) == 'string')
    opts.desc = list[2]
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

  -- vim.dbglog('opts', opts)
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
function M._to_mapping(mapping)
  mapping.silent = mapping.silent ~= false
  mapping.noremap = mapping.noremap ~= false
  if mapping.cmd and mapping.cmd:lower():find('^<plug>') then
    mapping.noremap = false
  end

  mapping.buf = mapping.buffer
  mapping.buffer = nil

  mapping.mode = mapping.mode or 'n'
  mapping.label = mapping.label or mapping.name or mapping.desc
  mapping.keys = Util.parse_keys(mapping.prefix or '')

  local opts = {}
  for _, o in ipairs(mapargs) do
    opts[o] = mapping[o]
    mapping[o] = nil
  end
  mapping.opts = opts
  return mapping
end

---@return Mapping[]
function M.parse(mappings, opts)
  opts = opts or {}
  local ret = {}
  M._try_parse(mappings, ret, opts)
  return vim.tbl_map(function(m)
    return M._to_mapping(m)
  end, ret)
end

return M
