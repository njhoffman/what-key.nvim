local state = require('which-key.extensions.view-list.state')

local M = {}

M.hide_debug = function()
  vim.dbglog('hide debug')
end

M.show_debug = function()
  vim.dbglog('show debug')

  -- local opts = {
  --   relative = 'editor',
  --   width = win_width,
  --   height = bounds.height.min,
  --   focusable = true,
  --   anchor = 'SW',
  --   border = config.options.window.border,
  --   row = row,
  --   col = margins[4],
  --   style = 'minimal',
  --   -- noautocmd = true,
  --   zindex = config.options.window.zindex,
  --   title = 'test title',
  --   title_pos = 'center',
  --   footer = 'test footer',
  --   footer_pos = 'left',
  -- }
  -- -- TODO: footer/title only if border set
  -- if config.options.window.position == 'top' then
  --   opts.anchor = 'NW'
  --   opts.row = margins[1]
  -- end
  --
  -- state.buf = vim.api.nvim_create_buf(false, true)
  -- state.win = vim.api.nvim_open_win(state.buf, false, opts)
  --
  -- vim.api.nvim_set_option_value('filetype', 'WhichKey', { buf = state.buf })
  -- vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.buf })
  -- vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.buf })
  -- vim.api.nvim_set_option_value('modifiable', true, { buf = state.buf })
  --
  -- local winhl = 'NormalFloat:WhichKeyFloat'
  -- if vim.fn.hlexists('FloatBorder') == 1 then
  --   winhl = winhl .. ',FloatBorder:WhichKeyBorder'
  -- end
  -- vim.api.nvim_set_option_value('winhighlight', winhl, { win = state.win })
  -- vim.api.nvim_set_option_value('foldmethod', 'manual', { win = state.win })
  -- vim.api.nvim_set_option_value('winblend', config.options.window.winblend, { win = state.win })
  --
end

M.update = function(map_group)
  vim.dbglog('update debug', map_group)
end

M.toggle_debug = function()
  state.debug.enabled = not state.debug.enabled
  if state.debug.enabled then
    state.cursor.callback = M.update
    M.show_debug()
  else
    M.hide_debug()
    state.cursor.callback = nil
  end
end

return M
