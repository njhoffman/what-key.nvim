local M = {}

M.right_align = function(name, width)
  name = name or ''
  return name .. string.rep(' ', width - #tostring(name))
end

M.key_counts = function()
  local hooks = require('which-key.keys.hooks')
  local counts = require('which-key.mapper').get_counts() or {}
  local line = '(' .. counts.ok or '--' .. ')'
  local modes = { 'n', 'v', 'i', 'o', 'c', 't' }
  for _, mode in ipairs(modes) do
    local count = counts['ok_' .. mode] or 0
    if line == '' then
      line = ' (' .. mode .. ':' .. count
    else
      line = line .. ' ' .. mode .. ':' .. count
    end
  end
  line = line
    .. ' ['
    .. ' '
    .. #vim.tbl_keys(hooks.hooked_auto)
    .. '  '
    .. #vim.tbl_keys(hooks.hooked_nop)
    .. ']'
  return line, counts
end

return M
