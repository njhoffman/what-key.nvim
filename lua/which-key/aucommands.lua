local Mapper = require('which-key.mapper')
local Keys = require('which-key.keys')
local Logger = require('which-key.logger')
local state = require('which-key.state')

local group = vim.api.nvim_create_augroup('WhichKey', { clear = true })

local register_queue = function(first_load)
  for _, reg in pairs(state.queue) do
    vim.schedule(function()
      local opts = reg[2] or {}
      Keys.register(reg[1], opts)
    end)
  end
  vim.schedule(function()
    state.queue = {}
    Keys.update()
    Keys.update(vim.api.nvim_get_current_buf())
    if first_load then
      Logger.log_startup(state.load_start)
    end
  end)
end

local get_buf = function(fn)
  return function(buf)
    return fn(
      type(buf) == 'number' and buf
        or type(buf) == 'table' and type(buf.buf) == 'number' and buf.buf
        or vim.api.nvim_get_current_buf()
    )
  end
end

local init_buffer_mappings = function(buf)
  state.buffers[buf] = vim.fn.reltime()
  state.loading[buf] = true
end

local load_buffer_mappings = function(buf)
  local diff = vim.fn.reltimestr(vim.fn.reltime(state.buffers[buf]))
  vim.dbglog('load buffer: ' .. diff)
  state.buffers[buf] = diff
  state.loading[buf] = false
  register_queue()
  -- local mode = Util.get_mode()
  -- Mapper.get_mappings(mode, '', buf)
  -- Keys.update(buf)
end

local unload_buffer_mappings = function(buf)
  if state.buffers[buf] then
    vim.dbglog('unload buffer: ' .. buf)
    -- local mode = Util.get_mode()
    -- Mapper.get_mappings(mode, '', buf)
    -- Keys.update(buf)
    state.buffers[buf] = nil
  end
end

local M = {}
M.register_queue = register_queue

M.schedule_load = function()
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    once = true,
    command = 'lua vim.defer_fn(require("which-key").load, 1)',
  })
end

M.setup = function()
  vim.api.nvim_create_autocmd({ 'BufReadPre' }, {
    group = group,
    callback = get_buf(init_buffer_mappings),
  })
  vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    group = group,
    callback = get_buf(load_buffer_mappings),
  })
  vim.api.nvim_create_autocmd({ 'BufDelete' }, {
    group = group,
    callback = get_buf(unload_buffer_mappings),
  })
end

return M
