local Config = require('which-key.config')
local Util = require('which-key.util')
local state = require('which-key.view.state')
local window = require('which-key.view.window')
local debug = require('which-key.view.debug')

local p_maps = Config.options.popup_mappings
local pu_maps = Config.options.popup_user_mappings

--stylua: ignore
local internal_maps = {
  [Util.t('<esc>')]             = 'hide',
  [Util.t('<bs>')]              = 'back',
  [Util.t(p_maps.page_down)]    = 'page_down',
  [Util.t(p_maps.page_up)]      = 'page_up',
  [Util.t(p_maps.scroll_up)]    = 'scroll_up',
  [Util.t(p_maps.scroll_down)]  = 'scroll_down',
  [Util.t(p_maps.toggle_debug)] = 'toggle_debug',
  [Util.t(p_maps.launch_wk)]    = 'launch_wk',
  [Util.t(p_maps.options_menu)] = 'options_menu',
  [Util.t(p_maps.help_menu)]    = 'help_menu',
}

local options_menu = function()
  vim.dbglog('options_menu')
end

local help_menu = function()
  vim.dbglog('help_menu')
end

--stylua: ignore
local actions = {
  options_menu = options_menu,
  help_menu    = help_menu,
  launch_wk    = window.open,
  hide         = window.hide,
  back         = window.back,
  page_down    = window.page_down,
  page_up      = window.page_up,
  scroll_down  = window.scroll_down,
  scroll_up    = window.scroll_up,
  toggle_debug = debug.toggle_debug
}

-- check if input matches user_popup_mappings config
local check_user_mappings = function(c, mode)
  local result = {}
  for k, fn in pairs(pu_maps) do
    if Util.t(k) == c then
      result = { key = k, mode = mode, user_mapping = true }
      fn(state.keys:sub(1, -1 - #c), mode)
      result = vim.tbl_deep_extend('force', result, window.hide() or {})
      break
    end
  end
  return result
end

local M = {}

M.action_keys = vim.tbl_deep_extend('force', vim.tbl_values(p_maps), { '<esc>', '<bs>' })

-- check if input matches local (internal) whichkey maps
function M.check_internal(c, mode)
  local result = {}
  local action_key = internal_maps[c]
  if action_key then
    result = { key = action_key, mode = mode }
    local map_fn = actions[action_key]
    result = vim.tbl_deep_extend('force', result, map_fn(c, mode) or {})
  else
    result = check_user_mappings(c, mode)
  end
  result = vim.tbl_isempty(result) and nil or result
  return result
end

return M
