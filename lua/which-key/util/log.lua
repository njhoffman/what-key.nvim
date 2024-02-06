local logger = require('logger').init('whichkey')

local M = {}

local get_logger = function(level)
  return function(msg, meta)
    if level == 'trace' then
      logger:trace(msg, meta)
    elseif level == 'debug' then
      logger:debug(msg, meta)
    elseif level == 'info' then
      logger:info(msg, meta)
    elseif level == 'warn' then
      logger:warn(msg, meta)
    elseif level == 'error' then
      logger:error(msg, meta)
    end
  end
end

local tostring = tostring
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

M.timing = function(opts, timing, num)
  -- command finishes here if async job
  if type(timing.command ~= 'string') then
    timing.command = vim.fn.reltimestr(vim.fn.reltime(timing.total))
  end

  if type(timing.total) ~= 'string' then
    timing.total = vim.fn.reltimestr(vim.fn.reltime(timing.total))
    timing.average = timing.total * 1000 / num
    logger:debug(opts.prompt_title .. ':' .. timing.average .. ' /' .. timing.total .. ' (' .. num .. ') ')
    -- opts.finder_type, '\n', timing.command, timing.first_entry,
  end
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
  line = line .. (' (' .. (map.mode or results.mode) .. ') ')
  line = line .. (type(results.prefix_i) == 'string' and results.prefix_i or '')
  line = line .. string.rep(' ', 5 - #(results.prefix_i or '')) .. ' ' .. #results.mappings .. ' maps'
  M.debug(line)
  -- .. (type(map.name) == 'string' and map.name or type(map.label) == 'string' and map.label or '')
end

local debug_flag = true
function M.enable_debug()
  debug_flag = true
end

function M.disable_debug()
  debug_flag = false
end

function M.trace(...)
  if debug_flag then
    logger:trace(...)
  end
end

function M.debug(...)
  if debug_flag then
    logger:debug(...)
  end
end

function M.log(...)
  vim.dbglog(...)
end

function M.info(...)
  logger:info(...)
end

function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = 'WhichKey' })
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = 'WhichKey' })
end

function M.right_align(name, width)
  name = name or ''
  return name .. string.rep(' ', width - #tostring(name))
end

return M
