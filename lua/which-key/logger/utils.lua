local M = {}

M.right_align = function(name, width)
  name = name or ''
  return name .. string.rep(' ', width - #tostring(name))
end

return M
