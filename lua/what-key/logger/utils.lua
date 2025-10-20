local M = {}

M.right_align = function(name, width)
  name = name or ""
  return name .. string.rep(" ", width - #tostring(name))
end

M.key_counts = function()
  local hooks = require("what-key.keys.hooks")
  local counts = require("what-key.mapper").get_counts() or {}
  local line = counts.ok or "--"
  local modes = { "n", "v", "i", "o", "c", "t" }
  for _, mode in ipairs(modes) do
    local count = counts["ok_" .. mode] or 0
    if line == "" then
      line = mode .. ":" .. count
    else
      line = line .. " " .. mode .. ":" .. count
    end
  end
  --   line = line
  --     .. ' ['
  --     .. ' '
  --     .. #vim.tbl_keys(hooks.hooked_auto)
  --     .. '  '
  --     .. #vim.tbl_keys(hooks.hooked_nop)
  --     .. ']'
  local bufnr = vim.api.nvim_get_current_buf()
  local bufcount = counts and counts.buffers and counts.buffers[bufnr]
  if bufcount and bufcount.ok then
    line = line .. " [" .. bufnr .. ":" .. bufcount.ok .. (bufcount.todo and ":" .. bufcount.todo or "") .. "]"
  end
  return line, counts
end

return M
