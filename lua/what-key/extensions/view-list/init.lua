local Config = require("what-key.config")
local view_utils = require("what-key.extensions.view-list.utils")
local state = require("what-key.extensions.view-list.state")

local highlight = vim.api.nvim_buf_add_highlight

local animate_height = function(win, height)
  local current_height = vim.api.nvim_win_get_height(win)
  if height > current_height then
    for i = current_height, height, 1 do
      vim.api.nvim_win_set_height(win, i)
      vim.cmd("redraw")
      vim.wait(1)
    end
  else
    for i = current_height, height, -1 do
      vim.api.nvim_win_set_height(win, i)
      vim.cmd("redraw")
      vim.wait(1)
    end
  end
  -- vim.api.nvim_win_set_height(state.win, height)
end

----@param text Text
local function render_list(text)
  local bounds = view_utils.get_bounds()
  local view = vim.api.nvim_win_call(state.win, vim.fn.winsaveview)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, text.lines)
  local height = #text.lines
  if height > bounds.height.max then
    height = bounds.height.max
  end

  animate_height(state.win, height)

  if view_utils.is_valid(state.buf, state.win) then
    vim.api.nvim_buf_clear_namespace(state.buf, Config.namespace, 0, -1)
  end
  for _, data in ipairs(text.hl) do
    highlight(state.buf, Config.namespace, data.group, data.line, data.from, data.to)
  end
  -- vim.api.nvim_win_call(state.win, function()
  --   vim.fn.winrestview(view)
  -- end)
end

local function render_footer(breadcrumbs)
  -- hl = { [1] = { from = 1, group = "WhatKeyMode", line = 0, to = 5 },
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

local function render_title(title)
  -- vim.api.nvim_win_set_config(state.win, {
  --     title = title.lines[1],
  --   })
  -- vim.api.nvim_win_set_option('footer', breadcrumbs.lines[1])
  -- vim.dbglog('**', title)
end

local window = require("what-key.extensions.view-list.window")
local Layout = require("what-key.extensions.view-list.layout")

local render = function(vstate, opts, map_group)
  if view_utils.is_enabled(vstate.parent_buf) then
    if not view_utils.is_valid(state.buf, state.win) then
      opts._load_window = true
      window.show()
    end

    local layout = Layout:new(map_group)
    render_list(layout:make_list())
    render_footer(layout:make_breadcrumbs())
    render_title(layout:make_title())
    --   M.show_debug()
  end
end

return { render = render }
