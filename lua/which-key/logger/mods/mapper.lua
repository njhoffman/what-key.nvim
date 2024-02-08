local M = {}

M.init = function(logger)
  M.logger = logger
end

function M.dump_lines(opts)
  opts = opts or {}
  local key_cats = require('which-key.keys').dump()
  local lines = {}

  for _, conflict in ipairs(key_cats.conflicts) do
    table.insert(lines, 'conf: ' .. conflict)
  end

  for _, cat in ipairs({ 'ok', 'todo', 'dupes' }) do
    for mode, keys in pairs(key_cats[cat]) do
      for key, def in pairs(keys) do
        local line = cat .. ': ' .. string.rep(' ', 5 - #cat) .. '(' .. mode .. ') ' .. '"' .. key .. '" ' .. def
        table.insert(lines, line)
      end
    end
  end

  for _, line in ipairs(lines) do
    M.debug(line)
  end
end

function M.dump_tree(opts)
  opts = opts or {}
  local key_cats = require('which-key.keys').dump()
  M.debug(key_cats)
end

return M
