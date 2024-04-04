local Mapper = require('which-key.mapper')
local Util = require('which-key.util')
local wk_view = require('which-key.view')
local actions = require('which-key.view.actions')

local view_utils = require('which-key.view.utils')

local timeoutlen = vim.o.timeoutlen

local state = {}

local function read_pending()
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

-- operators show as g@
local on_key = function(key)
  -- local isCmdlineSearch = vim.fn.getcmdtype():find('[/?]') ~= nil

  state.mode = vim.api.nvim_get_mode().mode
  -- local c = view_utils.getchar()
  -- read_pending()
  -- local results = Mapper.get_mappings(state.mode, state.keys, state.parent_buf)
  vim.dbglog(state.mode, vim.fn.keytrans(key), state.keys)

  -- pause here until another character entered (while panel open)
  -- state.internal = actions.check_internal(c, opts.mode)
  -- if state.internal and state.internal.exit == true then
  --   return
  -- elseif vim.tbl_isempty(state.internal) then
  --   state.keys = state.keys .. c
  --   if #c > 0 then
  --     vim.api.nvim_win_set_cursor(state.win, { 1, 1 })
  --   end
  -- end
end

local setup = function()
  local ns = vim.api.nvim_create_namespace('which-key')
  state.keys = ''
  state.history = {}
  state.internal = {}
  -- state.mode = Util.get_mode()
  state.mode = vim.api.nvim_get_mode().mode
  state.count = vim.api.nvim_get_vvar('count')
  state.reg = vim.api.nvim_get_vvar('register')
  state.parent_buf = vim.api.nvim_get_current_buf()

  -- vim.on_key(on_key, ns)
end

return { setup = setup }
