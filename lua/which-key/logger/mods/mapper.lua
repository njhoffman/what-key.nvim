local M = {}

M.init = function(logger)
  M.logger = logger
end

function M.log_counts()
  local counts = require('which-key.mapper').get_counts()
  local line = ''
  for mode, count in pairs(counts) do
    local m = vim.fn.split(mode, '_')
    if type(m[2]) == 'string' and m[1] == 'ok' then
      if line == '' then
        line = ' (' .. m[2] .. ':' .. count
      else
        line = line .. ' ' .. m[2] .. ':' .. count
      end
    end
  end
  M.logger.debug(line)
end

function M.dump_lines(opts)
  opts = opts or {}
  local key_cats = require('which-key.mapper').dump()
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
  local key_cats = require('which-key.mapper').dump()
  M.debug(key_cats)
end

return M
