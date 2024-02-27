local Config = require('which-key.config')
local Util = require('which-key.util')

local M = {}

function M.get_operator(prefix_i)
  for op_n, _ in pairs(Config.options.operators) do
    local op_i = Util.t(op_n)
    if prefix_i:sub(1, #op_i) == op_i then
      return op_i, op_n
    end
  end
end

function M.process_motions(ret, mode, prefix_i, buf)
  local op_i, op_n = '', ''

  if mode ~= 'v' then
    op_i, op_n = M.get_operator(prefix_i)
  end

  if (mode == 'n' or mode == 'v') and op_i then
    ret.mode_ex = mode .. 'o'
    local op_prefix_i = prefix_i:sub(#op_i + 1)
    local op_count = op_prefix_i:match('^(%d+)')
    if op_count == '0' or Config.options.motions.count == false then
      op_count = nil
    end
    if op_count then
      op_prefix_i = op_prefix_i:sub(#op_count + 1)
    end
    ret.op_prefix_i = op_prefix_i
    ret.op_i = op_i
    local op_results = require('which-key.mapper').get_mappings('o', op_prefix_i, buf)

    if not ret.mapping and op_results.mapping then
      ret.mode_ex = 'o'
      ret.mapping = op_results.mapping
      if not ret.mapping.prefix then
        vim.dbglog('++', ret)
      else
        ret.mapping.keys = Util.parse_keys(ret.mapping.prefix)
        ret.mapping.prefix = op_n .. (op_count or '') .. ret.mapping.prefix
      end
    end

    for _, mapping in pairs(op_results.mappings) do
      mapping.prefix = op_n .. (op_count or '') .. mapping.prefix
      mapping.keys = Util.parse_keys(mapping.prefix)
      table.insert(ret.mappings, mapping)
    end
  end
end

return M
