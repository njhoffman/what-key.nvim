local log_utils = require('what-key.logger.utils')

local M = {}

M.init = function(logger)
  M.logger = logger
end

function M.log_counts(title)
  title = title or ''
  if #title < 10 then
    title = title .. string.rep(' ', 10 - #title)
  end
  local line = title .. log_utils.key_counts()
  M.logger.debug(line)
end

function M.log_keys_summary(opts)
  opts = opts or {}
  local key_cats = require('what-key.mapper').dump()
  local lines = {}

  for _, conflict in ipairs(key_cats.conflicts) do
    table.insert(lines, 'conf: ' .. conflict)
  end

  for _, cat in ipairs({ 'ok', 'todo', 'dupes' }) do
    for mode, keys in pairs(key_cats[cat]) do
      for key, def in pairs(keys) do
        local line = cat
          .. ': '
          .. string.rep(' ', 5 - #cat)
          .. '('
          .. mode
          .. ') '
          .. '"'
          .. key
          .. '" '
          .. def
        table.insert(lines, line)
      end
    end
  end

  for _, line in ipairs(lines) do
    M.logger.debug(lines)
  end
end

function M.log_dump_tree(opts)
  opts = opts or {}
  local cats = require('what-key.mapper').dump()
  M.logger.debug(
    tostring(cats.counts.all)
      .. ' '
      .. tostring(cats.counts.ok)
      .. ' '
      .. vim.inspect(cats.counts.buffers)
  )
end

return M
