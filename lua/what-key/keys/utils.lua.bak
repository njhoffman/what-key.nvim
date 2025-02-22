local state = require('which-key.keys.state')

local M = {}

function M.map(mode, prefix_n, cmd, buf, opts)
  local other = vim.api.nvim_buf_call(buf or 0, function()
    local ret = vim.fn.maparg(prefix_n, mode, false, true)
    ---@diagnostic disable-next-line: undefined-field
    return ret and ret.lhs and ret.rhs and ret.rhs ~= cmd and ret or nil
  end)
  if other then
    table.insert(
      state.duplicates,
      { mode = mode, prefix = prefix_n, cmd = cmd, buf = buf, other = other }
    )
  end
  if buf ~= nil then
    pcall(vim.api.nvim_buf_set_keymap, buf, mode, prefix_n, cmd, opts)
  else
    pcall(vim.api.nvim_set_keymap, mode, prefix_n, cmd, opts)
  end
end

return M
