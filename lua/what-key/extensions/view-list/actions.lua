local Config = require("what-key.config")
local Util = require("what-key.util")

local preview = require("what-key.extensions.view-list.preview")
local state = require("what-key.extensions.view-list.state")
local window = require("what-key.extensions.view-list.window")
local debug = require("what-key.extensions.view-list.debug")

local maps = Config.options.mappings
local maps_u = Config.options.mappings_user

--stylua: ignore
local internal_maps = {
  [Util.t('<esc>')]           = 'hide',
  [Util.t('<bs>')]            = 'back',
  [Util.t(maps.page_down)]    = 'page_down',
  [Util.t(maps.page_up)]      = 'page_up',
  [Util.t(maps.scroll_up)]    = 'scroll_up',
  [Util.t(maps.scroll_down)]  = 'scroll_down',
  [Util.t(maps.toggle_debug)] = 'toggle_debug',
  [Util.t(maps.launch_wk)]    = 'launch_wk',
  [Util.t(maps.options_menu)] = 'options_menu',
  [Util.t(maps.help_menu)]    = 'help_menu',
}

local options_menu = function()
  vim.dbglog("options_menu")
end

local help_menu = function()
  vim.dbglog("help_menu")
end

--stylua: ignore
local actions = {
  options_menu   = options_menu,
  help_menu      = help_menu,
  launch_wk      = window.open,
  hide           = window.hide,
  back           = window.back,
  page_down      = window.page_down,
  page_up        = window.page_up,
  scroll_down    = window.scroll_down,
  scroll_up      = window.scroll_up,
  toggle_debug   = debug.toggle_debug,
  toggle_preview = preview.toggle_preview,
}

-- check if input matches user_popup_mappings config
local check_user_mappings = function(c, mode)
  local result = {}
  for k, fn in pairs(maps_u) do
    if Util.t(k) == c then
      result = { key = k, mode = mode, user_mapping = true }
      fn(string.sub(state.keys, 1, -1 - #c), mode)
      result = vim.tbl_deep_extend("force", result, window.hide() or {})
      break
    end
  end
  return result
end

local M = {}

M.action_keys = vim.tbl_deep_extend("force", vim.tbl_values(maps), { "<esc>", "<bs>" })

-- check if input matches local (internal) whatkey maps
function M.check_internal(c, mode)
  local result = {}
  local action_key = internal_maps[c]
  if action_key then
    result = { key = action_key, mode = mode }
    local map_fn = actions[action_key]
    result = vim.tbl_deep_extend("force", result, map_fn(c, mode) or {})
  else
    result = check_user_mappings(c, mode)
  end
  result = vim.tbl_isempty(result) and nil or result
  return result
end

return M
