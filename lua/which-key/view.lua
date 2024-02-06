local Keys = require('which-key.keys')
local config = require('which-key.config')
local Layout = require('which-key.layout')
local Util = require('which-key.util')

local highlight = vim.api.nvim_buf_add_highlight

local state = {
  keys = '',
  mode = 'n',
  reg = nil,
  count = 0,
  timing = {
    keys_n = 0,
    keys_average = 0,
    show_n = 0,
    show_average = 0,
  },
  history = {},
}

---@class View
local M = {}

M.auto = false
M.buf = nil
M.win = nil

M.state = state

function M.calculate_timings(opts)
  local time_diff = (vim.fn.reltimestr(vim.fn.reltime(opts._start_time))):sub(1, 8)
  local t = state.timing
  if opts._load_window then
    t.show_n = t.show_n + 1
    t.show_average = string.format('%.4f', t.show_average * (t.show_n - 1) / t.show_n + (time_diff / t.show_n))
  else
    t.keys_n = t.keys_n + 1
    t.keys_average = string.format('%.4f', t.keys_average * (t.keys_n - 1) / t.keys_n + (time_diff / t.keys_n))
  end
end

function M.is_valid()
  return M.buf
    and M.win
    and vim.api.nvim_buf_is_valid(M.buf)
    and vim.api.nvim_buf_is_loaded(M.buf)
    and vim.api.nvim_win_is_valid(M.win)
end

function M.show()
  if vim.b.visual_multi then
    vim.b.VM_skip_reset_once_on_bufleave = true
  end
  if M.is_valid() then
    return
  end

  -- non-floating windows
  local wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative == ''
  end, vim.api.nvim_list_wins())

  ---@type number[]
  local margins = {}
  for i, m in ipairs(config.options.window.margin) do
    if m > 0 and m < 1 then
      if i % 2 == 0 then
        m = math.floor(vim.o.columns * m)
      else
        m = math.floor(vim.o.lines * m)
      end
    end
    margins[i] = m
  end

  -- margin limit
  local border_val = config.options.window.border ~= 'none' and 2 or 0
  if margins[2] + margins[4] + border_val > vim.o.columns then
    margins[2] = 0
    margins[4] = 0
  end

  local bounds = Layout:get_bounds(config.options.layout)
  local win_width = math.max(bounds.width.min, vim.o.columns - margins[2] - margins[4] - border_val)
  local row = vim.o.lines
    - margins[3]
    - border_val
    + ((vim.o.laststatus == 0 or vim.o.laststatus == 1 and #wins == 1) and 1 or 0)
    - vim.o.cmdheight
    + 1

  local opts = {
    relative = 'editor',
    width = win_width,
    height = bounds.height.min,
    focusable = true,
    anchor = 'SW',
    border = config.options.window.border,
    row = row,
    col = margins[4],
    style = 'minimal',
    -- noautocmd = true,
    zindex = config.options.window.zindex,
    title = 'test title',
    title_pos = 'center',
    footer = 'test footer',
    footer_pos = 'left',
  }
  -- TODO: footer/title only if border set
  if config.options.window.position == 'top' then
    opts.anchor = 'NW'
    opts.row = margins[1]
  end
  M.buf = vim.api.nvim_create_buf(false, true)
  M.win = vim.api.nvim_open_win(M.buf, false, opts)

  vim.api.nvim_set_option_value('filetype', 'WhichKey', { buf = M.buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = M.buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = M.buf })
  vim.api.nvim_set_option_value('modifiable', true, { buf = M.buf })

  local winhl = 'NormalFloat:WhichKeyFloat'
  if vim.fn.hlexists('FloatBorder') == 1 then
    winhl = winhl .. ',FloatBorder:WhichKeyBorder'
  end
  vim.api.nvim_set_option_value('winhighlight', winhl, { win = M.win })
  vim.api.nvim_set_option_value('foldmethod', 'manual', { win = M.win })
  vim.api.nvim_set_option_value('winblend', config.options.window.winblend, { win = M.win })

  local old_fadelevel = nil
  vim.api.nvim_create_autocmd('WinClosed', {
    buffer = M.buf,
    nested = true,
    once = true,
    callback = function()
      if config.options.vimade_fade then
        vim.cmd('VimadeUnfadeActive')
        vim.cmd('VimadeFadeLevel ' .. old_fadelevel)
      end
      vim.api.nvim_exec_autocmds('ModeChanged', { pattern = state.mode .. ':' .. vim.api.nvim_get_mode().mode })
    end,
    group = 'WhichKey',
  })
  if config.options.vimade_fade then
    old_fadelevel = vim.api.nvim_get_var('vimade').fadelevel
    local fadelevel = type(config.options.vimade_fade) == 'number' and config.options.vimade_fade or 0.75
    vim.api.nvim_win_set_var(M.win, 'vimade_disabled', true)
    vim.cmd('VimadeFadeLevel ' .. fadelevel)
    vim.cmd('VimadeFadeActive')
  end
end

function M.read_pending()
  local esc = ''
  while true do
    local n = vim.fn.getchar(0)
    if n == 0 then
      break
    end
    local c = (type(n) == 'number' and vim.fn.nr2char(n) or n)

    -- HACK: for some reason, when executing a :norm command,
    -- vim keeps feeding <esc> at the end
    if c == Util.t('<esc>') then
      esc = esc .. c
      -- more than 10 <esc> in a row? most likely the norm bug
      if #esc > 10 then
        return
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
end

function M.getchar()
  local ok, n = pcall(vim.fn.getchar)

  -- bail out on keyboard interrupt
  if not ok then
    return Util.t('<esc>')
  end

  local c = (type(n) == 'number' and vim.fn.nr2char(n) or n)
  return c
end

function M.scroll(up)
  local delta = 1
  local height = vim.api.nvim_win_get_height(M.win)
  local cursor = vim.api.nvim_win_get_cursor(M.win)
  vim.api.nvim_set_option_value('scrolloff', height, { win = M.win })
  if up then
    cursor[1] = math.max(cursor[1] - delta, 1)
  else
    cursor[1] = math.min(cursor[1] + delta, vim.api.nvim_buf_line_count(M.buf) - math.ceil(height / 2))
    cursor[1] = math.max(cursor[1], math.ceil(height / 2) + 1)
  end
  vim.api.nvim_win_set_cursor(M.win, cursor)
end

function M.page(up)
  local height = vim.api.nvim_win_get_height(M.win)
  local cursor = vim.api.nvim_win_get_cursor(M.win)
  local delta = math.floor(height / 3)
  vim.api.nvim_set_option_value('scrolloff', height, { win = M.win })
  if up then
    cursor[1] = math.max(cursor[1] - delta, 1)
  else
    cursor[1] = math.min(cursor[1] + delta, vim.api.nvim_buf_line_count(M.buf) - math.ceil(height / 2))
    cursor[1] = math.max(cursor[1], math.ceil(height / 2) + 1)
  end
  vim.api.nvim_win_set_cursor(M.win, cursor)
end

function M.on_close()
  M.hide()
end

function M.hide()
  vim.api.nvim_echo({ { '' } }, false, {})
  M.hide_cursor()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    vim.api.nvim_buf_delete(M.buf, { force = true })
    M.buf = nil
  end
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
  end
  vim.cmd('redraw')
end

function M.show_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_add_highlight(buf, config.namespace, 'Cursor', cursor[1] - 1, cursor[2], cursor[2] + 1)
end

function M.hide_cursor()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, config.namespace, 0, -1)
end

function M.back()
  local node = Keys.get_tree(state.mode, M.buf).tree:get(state.keys, -1)
    or Keys.get_tree(state.mode).tree:get(state.keys, -1)
  if node then
    state.keys = node.prefix_i
  end
  state.history = table.remove(state.history, #state.history)
end

function M.execute(prefix_i, mode, buf)
  local global_node = Keys.get_tree(mode).tree:get(prefix_i)
  local buf_node = buf and Keys.get_tree(mode, buf).tree:get(prefix_i) or nil

  if global_node and global_node.mapping and Keys.is_hook(prefix_i, global_node.mapping.cmd) then
    return
  end
  if buf_node and buf_node.mapping and Keys.is_hook(prefix_i, buf_node.mapping.cmd) then
    return
  end

  local hooks = {}

  local function unhook(nodes, nodes_buf)
    for _, node in pairs(nodes) do
      if Keys.is_hooked(node.mapping.prefix, mode, nodes_buf) then
        table.insert(hooks, { node.mapping.prefix, nodes_buf })
        Keys.hook_del(node.mapping.prefix, mode, nodes_buf)
      end
    end
  end

  -- make sure we remove all WK hooks before executing the sequence
  -- this is to make existing keybindongs work and prevent recursion
  unhook(Keys.get_tree(mode).tree:path(prefix_i))
  if buf then
    unhook(Keys.get_tree(mode, buf).tree:path(prefix_i), buf)
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
      Keys.hook_add(hook[1], mode, hook[2])
    end
  end, 0)
end

function M.start(keys, opts)
  opts = opts or {}
  state.keys = keys or ''
  state.history = {}
  state.mode = opts.mode or Util.get_mode()
  state.count = vim.api.nvim_get_vvar('count')
  state.reg = vim.api.nvim_get_vvar('register')

  if string.find(vim.o.clipboard, 'unnamedplus') and state.reg == '+' then
    state.reg = '"'
  end

  if string.find(vim.o.clipboard, 'unnamed') and state.reg == '*' then
    state.reg = '"'
  end

  M.show_cursor()
  M.on_keys(opts)
end

function M.is_enabled(buf)
  local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
  for _, bt in ipairs(config.options.disable.buftypes) do
    if bt == buftype then
      return false
    end
  end

  local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
  for _, bt in ipairs(config.options.disable.filetypes) do
    if bt == filetype then
      return false
    end
  end

  return true
end

function M.process_mappings(results, opts)
  if #results.mappings == 0 then
    M.hide()
    if results.mapping and not results.mapping.group then
      --- Check for an exact match. Feedkeys with remap
      if results.mapping.fn then
        opts._op_icon = '󰡱'
        results.mapping.fn()
      else
        opts._op_icon = type(results.mapping.callback) == 'function' and '' or '󰞷'
        M.execute(state.keys, state.mode, state.parent_buf)
      end
    else
      if opts.auto then
        -- Check for no mappings found. Feedkeys without remap
        -- only execute if an actual key was typed while WK was open
        opts._op_icon = '∅'
        M.execute(state.keys, state.mode, state.parent_buf)
      end
    end
    return false
  end
  return true
end

function M.on_keys(opts)
  state.parent_buf = vim.api.nvim_get_current_buf()

  while true do
    -- loop
    M.read_pending()

    opts._load_window = false
    opts._op_icon = ''

    local results = Keys.get_mappings(state.mode, state.keys, state.parent_buf)
    local history = Util.without(results, 'mappings')
    history.children_n = Util.count(results.mappings)
    table.insert(state.history, history)

    if not M.process_mappings(results, opts) then
      M.calculate_timings(opts)
      Util.log_key(results, opts)
      return
    end

    local layout = Layout:new(results)

    if M.is_enabled(state.parent_buf) then
      if not M.is_valid() then
        opts._load_window = true
        M.show()
      end

      M.render(layout:make_list(M.win))
      M.render_footer(layout:make_breadcrumbs())
      M.render_title(layout:make_title())
    end

    vim.cmd([[redraw]])

    opts._op_icon = results.mapping.group == true and '󰐕' or ''
    M.calculate_timings(opts)
    Util.log_key(results, opts)

    -- pause here until another character entered (while panel open)
    local c = M.getchar()
    opts._start_time = vim.fn.reltime()

    if c == Util.t('<esc>') then
      M.hide()
      break
    elseif c == Util.t(config.options.popup_mappings.page_down) then
      M.page(false)
    elseif c == Util.t(config.options.popup_mappings.page_up) then
      M.page(true)
    elseif c == Util.t(config.options.popup_mappings.scroll_down) then
      M.scroll(false)
    elseif c == Util.t(config.options.popup_mappings.scroll_up) then
      M.scroll(true)
    elseif c == Util.t('<bs>') then
      M.back()
      vim.api.nvim_win_set_cursor(M.win, { 1, 1 })
    else
      state.keys = state.keys .. c
      if #c > 0 then
        vim.api.nvim_win_set_cursor(M.win, { 1, 1 })
      end
    end

    for k, fn in pairs(config.options.popup_user_mappings) do
      if c == Util.t(k) then
        fn(state.keys:sub(1, -1 - #c), opts.mode)
        M.hide()
        return
      end
    end
  end
end

----@param text Text
function M.render(text)
  local bounds = Layout:get_bounds(config.options.layout)
  local view = vim.api.nvim_win_call(M.win, vim.fn.winsaveview)
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, text.lines)
  local height = #text.lines
  if height > bounds.height.max then
    height = bounds.height.max
  end
  vim.api.nvim_win_set_height(M.win, height)
  if vim.api.nvim_buf_is_valid(M.buf) then
    vim.api.nvim_buf_clear_namespace(M.buf, config.namespace, 0, -1)
  end
  for _, data in ipairs(text.hl) do
    highlight(M.buf, config.namespace, data.group, data.line, data.from, data.to)
  end
  vim.api.nvim_win_call(M.win, function()
    vim.fn.winrestview(view)
  end)
end

function M.render_footer(breadcrumbs)
  -- hl = { [1] = { from = 1, group = "WhichKeyMode", line = 0, to = 5 },
  if breadcrumbs and breadcrumbs.lines then
    vim.api.nvim_win_set_config(M.win, {
      footer = breadcrumbs.lines[1],
    })
  end
  -- for _, data in ipairs(text.hl) do
  --   highlight(M.buf, config.namespace, data.group, data.line, data.from, data.to)
  -- end
  -- vim.api.nvim_win_call(M.win, function()
  --   vim.fn.winrestview(view)
  -- end)
end

function M.render_title(title)
  -- vim.api.nvim_win_set_config(M.win, {
  --     title = title.lines[1],
  --   })
  -- vim.api.nvim_win_set_option('footer', breadcrumbs.lines[1])
  -- vim.dbglog('**', title)
end

return M
