local Mapper = require("what-key.mapper")
local Config = require("what-key.config")
local view_utils = require("what-key.extensions.view-list.utils")
local state = require("what-key.extensions.view-list.state")

-- local win_id  -- window identifier. Replace it with actual window ID
-- local current_window = vim.api.nvim_win_get_viewport(win_id)
-- vim.api.nvim_win_set_viewport(win_id, current_window.topline + 1, current_window.botline, current_window.left_column, current_window.right_column)

local scroll = function(up, scrolloff)
  local delta = 1
  local height = vim.api.nvim_win_get_height(state.win)
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  vim.api.nvim_set_option_value("scrolloff", height, { win = state.win })
  if up then
    cursor[1] = math.max(cursor[1] - delta, 1)
  else
    cursor[1] = math.min(cursor[1] + delta, vim.api.nvim_buf_line_count(state.buf) - math.ceil(height / 2) + 1)
    cursor[1] = math.max(cursor[1], math.ceil(height / 2) + 1)
  end
  view_utils.set_cursor(cursor[1])
end

local page = function(up)
  local height = vim.api.nvim_win_get_height(state.win)
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local delta = math.floor(height / 3)
  vim.api.nvim_set_option_value("scrolloff", height, { win = state.win })
  if up then
    cursor[1] = math.max(cursor[1] - delta, 1)
  else
    cursor[1] = math.min(cursor[1] + delta, vim.api.nvim_buf_line_count(state.buf) - math.ceil(height / 2) + 1)
    cursor[1] = math.max(cursor[1], math.ceil(height / 2) + 1)
  end
  view_utils.set_cursor(cursor[1])
end

local M = {}

M.scroll_up = function()
  scroll(true)
end

M.scroll_down = function()
  scroll()
end

M.page_up = function()
  page(true)
end

M.page_down = function()
  page()
end

function M.show()
  if vim.b.visual_multi then
    vim.b.VM_skip_reset_once_on_bufleave = true
  end
  if view_utils.is_valid() then
    return
  end

  -- non-floating windows
  local wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative == ""
  end, vim.api.nvim_list_wins())

  ---@type number[]
  local margins = {}
  for i, m in ipairs(Config.options.window.margin) do
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
  local border_val = Config.options.window.border ~= "none" and 2 or 0
  if margins[2] + margins[4] + border_val > vim.o.columns then
    margins[2] = 0
    margins[4] = 0
  end

  local bounds = view_utils.get_bounds()
  local win_width = math.max(bounds.width.min, vim.o.columns - margins[2] - margins[4] - border_val)
  local row = vim.o.lines
    - margins[3]
    - border_val
    + ((vim.o.laststatus == 0 or vim.o.laststatus == 1 and #wins == 1) and 1 or 0)
    - vim.o.cmdheight
    + 1

  local opts = {
    relative = "editor",
    width = win_width,
    height = bounds.height.min,
    focusable = true,
    anchor = "SW",
    border = Config.options.window.border,
    row = row,
    col = margins[4],
    style = "minimal",
    -- noautocmd = true,
    zindex = Config.options.window.zindex,
    title = "test title",
    title_pos = "center",
    footer = "test footer",
    footer_pos = "right",
  }
  -- TODO: footer/title only if border set
  if Config.options.window.position == "top" then
    opts.anchor = "NW"
    opts.row = margins[1]
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  state.win = vim.api.nvim_open_win(state.buf, false, opts)

  vim.api.nvim_set_option_value("filetype", "WhatKey", { buf = state.buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })

  local winhl = "NormalFloat:WhatKeyFloat,CursorLine:WhatKeyCursorLine"
  if vim.fn.hlexists("FloatBorder") == 1 then
    winhl = winhl .. ",FloatBorder:WhatKeyBorder"
  end
  vim.api.nvim_set_option_value("winhighlight", winhl, { win = state.win })
  vim.api.nvim_set_option_value("foldmethod", "manual", { win = state.win })

  vim.api.nvim_set_option_value("winblend", Config.options.window.winblend, { win = state.win })
  vim.api.nvim_set_option_value("cursorline", true, { win = state.win })

  local old_fadelevel = nil
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = state.buf,
    nested = true,
    once = true,
    callback = function(ev)
      if Config.options.vimade_fade then
        vim.cmd("VimadeUnfadeActive")
        vim.cmd("VimadeFadeLevel " .. old_fadelevel)
      end

      -- local vstate = require('what-key.view.state')
      -- vim.api.nvim_exec_autocmds(
      --   'ModeChanged',
      --   { pattern = vstate.mode .. ':' .. vim.api.nvim_get_mode().mode }
      -- )

      -- local winid = tonumber(ev.match)
      -- local blend = vim.api.nvim_win_get_option(winid, 'winblend')
      -- while blend < 100 do
      --   blend = blend + 2
      --   vim.api.nvim_win_set_option(winid, 'winblend', blend)
      --   vim.cmd('redraw')
      --   vim.wait(2)
      -- end
    end,
    group = "WhatKey",
  })

  if Config.options.vimade_fade then
    old_fadelevel = vim.api.nvim_get_var("vimade").fadelevel
    local fadelevel = type(Config.options.vimade_fade) == "number" and Config.options.vimade_fade or 0.75
    vim.api.nvim_win_set_var(state.win, "vimade_disabled", true)
    vim.cmd("VimadeFadeLevel " .. fadelevel)
    vim.cmd("VimadeFadeActive")
  end
end

function M.hide()
  vim.api.nvim_echo({ { "" } }, false, {})
  view_utils.hide_cursor()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
    state.buf = nil
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
  vim.cmd("redraw")
  return { exit = true }
end

M.launch_wk = function()
  vim.dbglog("launch_wk")
end

function M.back()
  local vstate = require("what-key.view.state")
  if vstate.keys ~= "" then
    local node = Mapper.get_tree(vstate.mode, vstate.buf).tree:get(vstate.keys, -1)
      or Mapper.get_tree(vstate.mode).tree:get(vstate.keys, -1)
    state.cursor.row = 1
    if node then
      vstate.keys = node.prefix_i
      state.cursor.row = state.cursor.history[vstate.mode .. "_" .. node.prefix_i] or 1
    end
    return { redraw = true }
  end
  -- state.history = table.remove(state.history, #state.history)
end

return M
