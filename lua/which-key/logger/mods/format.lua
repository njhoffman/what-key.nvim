local M = {}

M.init = function(logger)
  M.logger = logger
end

local last_prefix = ''
function M.log_key(results, opts)
  -- ﳠ ∅  󰐕   落  󰞷 󰡱  ﮜ 
  -- prevent logging duplicate key
  if false and (results.mode .. results.prefix_i) == last_prefix then
    return
  end
  last_prefix = results.mode .. results.prefix_i

  -- convert to seconds
  local time_diff = vim.fn.reltime(opts._start_time)
  time_diff = vim.fn.reltimestr(time_diff) -- * 1000
  local map = results.mapping or {}
  local line = ''
  line = line
    .. (opts._op_icon and opts._op_icon or '  ')
    .. (opts._load_window == true and ' ' or '  ')
    .. time_diff:sub(1, 8)

  local mode = results.mode_long or map.mode or results.mode
  line = line .. (' (' .. mode .. ') ')
  line = line .. (type(results.prefix_i) == 'string' and results.prefix_i or '')
  line = line .. string.rep(' ', 5 - #(results.prefix_i or '')) .. ' ' .. #results.mappings .. ' maps'
  M.logger.debug(line)
  -- .. (type(map.name) == 'string' and map.name or type(map.label) == 'string' and map.label or '')
end

function M.log_startup(start_time, counts, hooks)
  local time_diff = vim.fn.reltimestr(vim.fn.reltime(start_time))
  local line = 'load ' .. time_diff:sub(1, 8) .. '  ' .. counts.ok
  local sub_line = ''
  for mode, count in pairs(counts) do
    local m = vim.fn.split(mode, '_')
    if type(m[2]) == 'string' and m[1] == 'ok' then
      if sub_line == '' then
        sub_line = ' (' .. m[2] .. ':' .. count
      else
        sub_line = sub_line .. ' ' .. m[2] .. ':' .. count
      end
    end
  end
  line = line .. sub_line .. ')'
  line = line
    .. ' ['
    .. #vim.tbl_keys(hooks.hooked)
    .. '.'
    .. #vim.tbl_keys(hooks.auto)
    .. '.'
    .. #vim.tbl_keys(hooks.nop)
    .. ' hooks]'
  M.logger.debug(line)
end

M.timing_summary = function()
  local state = require('which-key.view').state
  local lineout = ''
  if state.timing.show_n > 0 then
    lineout = lineout .. string.format('**show**   `%.4f` %2d', state.timing.show_average, state.timing.show_n)
  end
  if state.timing.keys_n > 0 then
    lineout = lineout ~= '' and lineout .. '\n' or lineout
    lineout = lineout .. string.format('**keys**   `%.4f` %2d', state.timing.keys_average, state.timing.keys_n)
  end
  if lineout ~= '' then
    vim.notify(lineout, vim.log.levels.INFO, {
      filetype = 'markdown',
    })
  end
end

return M
