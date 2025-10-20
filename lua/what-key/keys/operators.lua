local Config = require("what-key.config")
local Util = require("what-key.util")

local M = {}

function M.get_operator(prefix_i)
  local op_keys = vim.tbl_keys(Config.options.operators)
  table.sort(op_keys, function(a, b)
    if #a == #b then
      return a < b
    end
    return #a > #b
  end)
  for _, op_n in ipairs(op_keys) do
    local op_desc = Config.options.operators[op_n] or op_n
    local op_i = Util.t(op_n)
    if prefix_i:sub(1, #op_i) == op_i then
      return op_i, op_n, op_desc
    end
  end
end

function M.process_motions(map_group, mode, prefix_i, buf)
  local op_i, op_n, op_desc = nil, nil, nil

  if mode == "n" then
    op_i, op_n, op_desc = M.get_operator(prefix_i)
  end

  if op_i then
    local op_prefix_i = prefix_i:sub(#op_i + 1)
    local op_count = op_prefix_i:match("^(%d+)")
    if op_count == "0" or Config.options.motions.count == false then
      op_count = nil
    end
    if op_count then
      op_prefix_i = op_prefix_i:sub(#op_count + 1)
    end
    map_group.op_prefix_i = op_prefix_i
    map_group.op_i = op_i
    map_group.mode = mode .. "o"

    -- special operator mode before motion (movement or object) command
    -- i.e. movement: (no)d -> (n)l , object: (no)d -> (o)i -> (n)w

    local motion_results = require("what-key.mapper").get_mappings("o", op_prefix_i, buf)
    if not map_group.mapping and motion_results.mapping then
      -- motion command (operator pending + object)
      map_group.mapping = vim.tbl_deep_extend("force", {}, motion_results.mapping)
      map_group.mapping.prefix = op_n .. (op_count or "") .. map_group.mapping.prefix
      map_group.mapping.keys = Util.parse_keys(map_group.mapping.prefix)
    end

    for _, child_map in pairs(motion_results.children) do
      child_map.prefix = op_n .. (op_count or "") .. child_map.prefix
      child_map.keys = Util.parse_keys(child_map.prefix)
      table.insert(map_group.children, child_map)
    end
  end

  if #vim.tbl_keys(map_group.children) > 0 then
    map_group.mapping.group = map_group.mapping.group or "multi"
    map_group.mapping.child_count = #vim.tbl_keys(map_group.children)
  end
end

return M
