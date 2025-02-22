local Logger = require("which-key.logger")
local Util = require("which-key.util")
local mapper_utils = require("which-key.mapper.utils")

-- "<buffer>", "<expr>", "<nowait>", "<silent>", "<script>",  "<unique>"
-- "desc" human-readable description
-- "callback" if keymap.set rhs is a function or included in nvim_set_keymap option
-- "replace_keycodes" (termcodes) keymap.set defaults to `true` if "expr" is `true`

-- keymap fields that will be removed from base table and saved to mapping.opts field
local keymap_fields = {
  "buffer",
  "callback",
  "desc",
  "expr",
  "noremap",
  "nowait",
  "replace_keycodes", -- TODO: add config setting for default value
  "script",
  "silent",
  "unique",
}

-- whichkey specific fields when registering keymaps and saved to mapping.meta field
local register_fields = {
  "category",
  "cond",
  "name",
  "icon",
  "plugin",
  -- 'prefix', TODO: mapping.prefix to mapping.keys.raw
  "preset",
  "remap",
  -- -- wk args
  --  plugin = { inherit = true },
  --  group = {},
  --  hidden = { inherit = true },
  --  cond = { inherit = true },
  --  preset = { inherit = true },
  --  icon = { inherit = true },
  --  proxy = {},
  --  expand = {},
  --  -- deprecated
  --  name = { transform = "group", deprecated = true },
  --  prefix = { inherit = true, deprecated = true },
  --  cmd = { transform = "rhs", deprecated = true },
}

-- fields for for the mapgroup.mapping item
local mapping_fields = {
  "icon",
  "child_count",
  "cmd",
  "group",
  "keys",
  "name",
  "meta",
  "mode",
  "opts",
  "preset",
  -- TODO: mapping.prefix to mapping.keys.raw
  "prefix",
  "type",
}

local child_fields = mapper_utils.lookup({
  "icon",
  "buffer",
  "expr",
  "mode",
  "noremap",
  "nowait",
  "prefix",
  "preset",
  "replace_keycodes",
  "script",
  "silent",
  "unique",
})

-- child_count = 14,
-- group = "multi",
-- key = "t",
-- keys = {
--     internal = {
--         [1] = "g",
--         [2] = "t"
--     },
--     notation = {
--         [1] = "g",
--         [2] = "t"
--     },
--     raw = "gt"
-- },
-- label = "+text-case ï ",
-- meta = {
--     name = "text-case ï "
-- },
-- mode = "n",
-- opts = {
--     noremap = true,
--     silent = true
-- },
-- prefix = "gt"

local args = mapper_utils.lookup(keymap_fields, mapping_fields)

local M = {}

function M._child_opts(opts)
  local child_opts = {}
  for k, v in pairs(opts) do
    if child_fields[k] then
      child_opts[k] = v
    end
  end
  return child_opts
end

-- handle different patterns of register mappings
-- register({ f = { name = "file", f = { "cmd", "Find File" } } }, { prefix = "<leader>" })
-- register({ ['<leader>'] = { f = { name = '+file', f = { 'cmd', 'Find File' } } } } )
-- register({ ['<leader>f'] = { name = '+file', f = { 'cmd', 'Find File' } } } )

function M._process(maps, reg_opts)
  local list, children = {}, {}
  for key, val in pairs(maps) do
    if type(val) == "function" then
      val = val()
    end
    if type(key) == "number" then
      if type(val) == "table" then
        -- nested child, without key
        table.insert(children, val)
      else
        -- list value
        table.insert(list, val)
      end
    elseif args[key] then
      -- option
      reg_opts[key] = val
    else
      -- nested child, with key
      children[key] = val
    end
  end
  return list, children
end

-- build new mapping objects
function M._build_maps(maps, opts, new_maps)
  -- don't add if cond is defined and not true
  if opts.cond ~= nil then
    if type(opts.cond) == "function" then
      if not opts.cond() then
        return
      end
    elseif not opts.cond then
      return
    end
  end

  -- separate children for later recursive handling
  local list, children = M._process(maps, opts)

  if opts.name then
    opts.name = opts.name and opts.name:gsub("^%+", "")
    opts.group = opts.group or "prefix"
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

  -- { desc }
  if #list == 1 then
    if type(list[1]) ~= "string" then
      error("Invalid mapping for " .. vim.inspect({ value = maps, opts = opts }))
    end
    opts.desc = list[1]
  -- { cmd, desc }
  elseif #list == 2 then
    assert(type(list[2]) == "string")
    opts.desc = list[2]
    if type(list[1]) == "string" then
      opts.cmd = list[1]
    elseif type(list[1]) == "function" then
      opts.cmd = ""
      opts.callback = list[1]
    else
      error("Incorrect mapping " .. vim.inspect(list))
    end
  elseif #list > 2 then
    error("Incorrect mapping " .. vim.inspect(list))
  end

  if opts.desc or opts.group then
    if type(opts.mode) == "table" then
      for _, mode in pairs(opts.mode) do
        local mode_opts = vim.deepcopy(opts)
        mode_opts.mode = mode
        table.insert(new_maps, mode_opts)
      end
    else
      table.insert(new_maps, opts)
    end
  end

  -- process any array child mappings
  for k, v in pairs(children) do
    local child_opts = M._child_opts(opts)
    if type(k) == "string" then
      child_opts.prefix = (child_opts.prefix or "") .. k
    end
    M._try_build_maps(v, child_opts, new_maps)
  end
end

-- parse new mapping object
---@return Mapping
function M._parse_mapping(mapping)
  mapping.silent = mapping.silent ~= false
  mapping.noremap = mapping.noremap ~= false
  if mapping.cmd and mapping.cmd:lower():find("^<plug>") then
    mapping.noremap = false
  end

  mapping.buf = mapping.buffer
  mapping.buffer = nil

  -- mapping.mode = mapping.mode or 'n'
  mapping.label = mapping.name or mapping.label or mapping.desc
  mapping.keys = Util.parse_keys(mapping.prefix or "")

  local opts = {}
  for _, o in ipairs(keymap_fields) do
    opts[o] = mapping[o]
    mapping[o] = nil
  end
  mapping.opts = opts

  local meta = {}
  for _, o in ipairs(register_fields) do
    meta[o] = mapping[o]
    mapping[o] = nil
  end
  mapping.meta = meta

  return mapping
end

function M._try_build_maps(reg_maps, reg_opts, new_maps)
  reg_maps = type(reg_maps) ~= "table" and { reg_maps } or reg_maps
  reg_opts = reg_opts or {}

  local ok, err = pcall(M._build_maps, reg_maps, reg_opts, new_maps)
  if not ok then
    Logger.error(err)
  end
  return new_maps
end

---@param reg_maps string[] table of mappings called with register command
---@param reg_opts string[] table of whichkey register options
---@return Mapping[]
function M.parse(reg_maps, reg_opts)
  local new_maps = {}
  M._try_build_maps(reg_maps, reg_opts, new_maps)

  local parsed_maps = vim.tbl_map(function(map)
    return M._parse_mapping(map)
  end, new_maps)

  return parsed_maps
end

return M
