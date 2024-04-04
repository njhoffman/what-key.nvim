local log_utils = require('which-key.logger.utils')

local M = {}

M.init = function(logger)
  M.logger = logger
end

local last_prefix = ''
M.log_key = function(results, opts, internal_key)
  -- ﳠ ∅  󰐕   落  󰞷 󰡱  ﮜ 
  if internal_key and not vim.tbl_isempty(internal_key) and internal_key.key ~= 'back' then
    return
  end

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

  local mode = results.mode or map.mode
  line = line .. ' (' .. mode .. ') ' .. (#mode == 2 and ' ' or '  ')
  line = line .. (type(results.prefix_i) == 'string' and vim.fn.keytrans(results.prefix_i) or '')
  line = line
    .. string.rep(' ', 9 - #(results.prefix_i or '') - #tostring(#results.mappings))
    .. #results.mappings
    .. '   '
  M.logger.debug(line)
end

M.log_startup = function(start_time)
  local time_diff = vim.fn.reltimestr(vim.fn.reltime(start_time))
  local title = '襤' .. time_diff:sub(1, 8) .. '  '
  local line = title .. log_utils.key_counts()
  M.logger.debug(line)
end

M.timing_summary = function()
  local state = require('which-key.view').state
  local lineout = ''
  if state.timing.show_n > 0 then
    lineout = lineout
      .. string.format('**show**   `%.4f` %2d', state.timing.show_average, state.timing.show_n)
  end
  if state.timing.keys_n > 0 then
    lineout = lineout ~= '' and lineout .. '\n' or lineout
    lineout = lineout
      .. string.format('**keys**   `%.4f` %2d', state.timing.keys_average, state.timing.keys_n)
  end
  if lineout ~= '' then
    vim.notify(lineout, vim.log.levels.INFO, {
      filetype = 'markdown',
    })
  end
end

return M
