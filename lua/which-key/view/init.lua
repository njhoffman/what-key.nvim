local Mapper = require('which-key.mapper')
local Config = require('which-key.config')
local Layout = require('which-key.layout')
local Util = require('which-key.util')
local Logger = require('which-key.logger')
local Hooks = require('which-key.keys.hooks')

local state = require('which-key.view.state')
local view_utils = require('which-key.view.utils')
local actions = require('which-key.view.actions')
local window = require('which-key.view.window')
-- local debug = require('which-key.view.debug')

local highlight = vim.api.nvim_buf_add_highlight

---@class View
local M = {}

M.state = state

function M.read_pending()
  local esc = ''
  while true do
    local n = vim.fn.getchar(0)
    if n == 0 then
      break
    end

    state.internal = actions.check_internal(n, state.mode)
    if state.internal and not vim.tbl_isempty(state.internal) then
      break
    end

    local c = (type(n) == 'number' and vim.fn.nr2char(n) or n)

    -- HACK: for some reason, when executing a :norm command,
    -- vim keeps feeding <esc> at the end
    if c == Util.t('<esc>') then
      esc = esc .. c
      -- more than 10 <esc> in a row? most likely the norm bug
      if #esc > 10 then
        return false
      end
    else
      -- we have <esc> characters, so add them to keys
      if esc ~= '' then
        state.keys = state.keys .. esc
        esc = ''
      end
      state.keys = state.keys .. c
    end
  end
  if esc ~= '' then
    state.keys = state.keys .. esc
    esc = ''
  end
  return true
end

function M.execute(prefix_i, mode, buf)
  local global_node = Mapper.get_tree(mode).tree:get(prefix_i)
  local buf_node = buf and Mapper.get_tree(mode, buf).tree:get(prefix_i) or nil

  if global_node and global_node.mapping and Hooks.is_hook(prefix_i, global_node.mapping.cmd) then
    return
  end
  if buf_node and buf_node.mapping and Hooks.is_hook(prefix_i, buf_node.mapping.cmd) then
    return
  end

  local hooks = {}

  local function unhook(nodes, nodes_buf)
    for _, node in pairs(nodes) do
      if Hooks.is_hooked(node.mapping.prefix, mode, nodes_buf) then
        table.insert(hooks, { node.mapping.prefix, nodes_buf })
        Hooks.hook_del(node.mapping.prefix, mode, nodes_buf)
      end
    end
  end

  -- make sure we remove all WK hooks before executing the sequence
  -- this is to make existing keybindongs work and prevent recursion
  unhook(Mapper.get_tree(mode).tree:path(prefix_i))
  if buf then
    unhook(Mapper.get_tree(mode, buf).tree:path(prefix_i), buf)
  end

  -- feed CTRL-O again if called from CTRL-O
  local full_mode = Util.get_mode()
  if full_mode == 'nii' or full_mode == 'nir' or full_mode == 'niv' or full_mode == 'vs' then
    vim.api.nvim_feedkeys(Util.t('<C-O>'), 'n', false)
  end

  -- handle registers that were passed when opening the popup
  if state.reg ~= '"' and state.mode ~= 'i' and state.mode ~= 'c' then
    vim.api.nvim_feedkeys('"' .. state.reg, 'n', false)
  end

  if state.count and state.count ~= 0 then
    prefix_i = state.count .. prefix_i
  end

  -- feed the keys with remap
  vim.api.nvim_feedkeys(prefix_i, 'm', true)

  -- defer hooking WK until after the keys were executed
  vim.defer_fn(function()
    for _, hook in pairs(hooks) do
      Hooks.hook_add(hook[1], mode, hook[2])
    end
  end, 0)
end

function M.handle_mapping(results, opts)
  if vim.tbl_isempty(results.children) and vim.tbl_isempty(state.internal) then
    window.hide()
    if results.mapping and not results.mapping.group then
      --- check for an exact match, feedkeys with remap
      if results.mapping.fn then
        opts._op_icon = '󰡱'
        results.mapping.fn()
      else
        opts._op_icon = type(results.mapping.callback) == 'function' and '' or '󰞷'
        M.execute(state.keys, state.mode, state.parent_buf)
      end
    elseif opts.auto then
      --  no mappings found, feedkeys without remap if WK is open
      opts._op_icon = '∅'
      M.execute(state.keys, state.mode, state.parent_buf)
    end
    return false
  end
  return true
end

function M.init_state(keys, opts)
  state.keys = keys or ''
  -- state.history = {}
  state.internal = {}
  state.mode = opts.mode or Util.get_mode()
  state.count = vim.api.nvim_get_vvar('count')
  state.reg = vim.api.nvim_get_vvar('register')
  state.parent_buf = opts.buf or vim.api.nvim_get_current_buf()
  if opts.background ~= nil then
    state.background = not state.background
    Logger.info('Background mode ' .. (state.background and 'enabled' or 'disabled'))
  end

  if string.find(vim.o.clipboard, 'unnamedplus') and state.reg == '+' then
    state.reg = '"'
  end

  if string.find(vim.o.clipboard, 'unnamed') and state.reg == '*' then
    state.reg = '"'
  end
end

function M.on_keys(keys, opts)
  opts = opts or {}
  M.init_state(keys, opts)

  view_utils.show_cursor()

  while true do
    M.read_pending()

    opts._load_window = false
    opts._op_icon = ''

    local map_group = Mapper.get_mappings(state.mode, state.keys, state.parent_buf)

    vim.dbglog(Util.without(map_group, 'children'))
    Util.update_mode(map_group.mode, map_group.op_i)

    if view_utils.is_valid(state.buf, state.win) then
      local cursor = vim.api.nvim_win_get_cursor(state.win)
      state.cursor.history[map_group.mode .. '_' .. map_group.prefix_i] = cursor[1]
    end

    -- if no child mappings log and quit
    if not M.handle_mapping(map_group, opts) then
      view_utils.calculate_timings(opts)
      Logger.log_key(map_group, opts, state.internal)
      return
    end

    if view_utils.is_enabled(state.parent_buf) then
      if not view_utils.is_valid(state.buf, state.win) then
        opts._load_window = true
        window.show()
      end

      local layout = Layout:new(map_group)

      M.render(layout:make_list(layout))
      M.render_footer(layout:make_breadcrumbs())
      M.render_title(layout:make_title())
      --   M.show_debug()
    end

    vim.cmd([[redraw]])

    -- M.set_cursor(state.cursor.row or 1)
    opts._op_icon = map_group and map_group.mapping and map_group.mapping.group == true and '󰐕'
      or ''
    view_utils.calculate_timings(opts)
    Logger.log_key(map_group, opts, state.internal)

    -- pause here until another character entered (while panel open)
    local c = view_utils.getchar()

    opts._start_time = vim.fn.reltime()

    state.internal = actions.check_internal(c, opts.mode)

    -- if not exit code append character to keys and reset cursor to top
    if state.internal and state.internal.exit == true then
      break
    elseif vim.tbl_isempty(state.internal) then
      state.keys = state.keys .. c
      if #c > 0 then
        vim.api.nvim_win_set_cursor(state.win, { 1, 1 })
      end
    end
  end
end

----@param text Text
function M.render(text)
  local bounds = view_utils.get_bounds()
  local view = vim.api.nvim_win_call(state.win, vim.fn.winsaveview)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, text.lines)
  local height = #text.lines
  if height > bounds.height.max then
    height = bounds.height.max
  end
  vim.api.nvim_win_set_height(state.win, height)
  if view_utils.is_valid(state.buf, state.win) then
    vim.api.nvim_buf_clear_namespace(state.buf, Config.namespace, 0, -1)
  end
  for _, data in ipairs(text.hl) do
    highlight(state.buf, Config.namespace, data.group, data.line, data.from, data.to)
  end
  vim.api.nvim_win_call(state.win, function()
    vim.fn.winrestview(view)
  end)
end

function M.render_footer(breadcrumbs)
  -- hl = { [1] = { from = 1, group = "WhichKeyMode", line = 0, to = 5 },
  if breadcrumbs and breadcrumbs.lines then
    vim.api.nvim_win_set_config(state.win, {
      footer = breadcrumbs.lines[1],
    })
  end
  -- for _, data in ipairs(text.hl) do
  --   highlight(state.buf, config.namespace, data.group, data.line, data.from, data.to)
  -- end
  -- vim.api.nvim_win_call(state.win, function()
  --   vim.fn.winrestview(view)
  -- end)
end

function M.render_title(title)
  -- vim.api.nvim_win_set_config(state.win, {
  --     title = title.lines[1],
  --   })
  -- vim.api.nvim_win_set_option('footer', breadcrumbs.lines[1])
  -- vim.dbglog('**', title)
end

return M
