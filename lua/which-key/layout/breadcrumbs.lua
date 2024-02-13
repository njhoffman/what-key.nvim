local Config = require('which-key.config')
local Mapper = require('which-key.mapper')
local Logger = require('which-key.logger')
local state = require('which-key.view.state')

local render_breadcrumbs = function(self)
  if not self.results.mapping then
    Logger.debug('No mapping found for breadcrumbs: ' .. vim.inspect(self.results))
    return
  end

  local win_width = vim.api.nvim_win_get_width(state.win)

  local prefix_i = self.results.prefix_i
  local mode = self.results.mode_long or self.results.mapping.mode or self.results.mode
  local buf_path = Mapper.get_tree(mode, self.results.buf).tree:path(prefix_i)
  local path = Mapper.get_tree(mode).tree:path(prefix_i)
  local len = #self.results.mapping.keys.notation
  local cmd_line = { { '(' .. mode .. ') ', 'WhichKeyMode' } }

  for i = 1, len, 1 do
    local node = buf_path[i]
    if not (node and node.mapping and node.mapping.label) then
      node = path[i]
    end
    local step = self.mapping.keys.notation[i]
    if node and node.mapping and node.mapping.label then
      step = Config.options.icons.group .. node.mapping.label
    end

    if Config.options.key_labels[step] then
      step = Config.options.key_labels[step]
    end
    table.insert(cmd_line, { step, 'WhichKeyGroup' })
    if i ~= #self.mapping.keys.notation then
      table.insert(cmd_line, { ' ' .. Config.options.icons.breadcrumb .. ' ', 'WhichKeySeparator' })
    end
  end

  if vim.o.cmdheight > 0 then
    vim.api.nvim_echo(cmd_line, false, {})
    vim.cmd([[redraw]])
  end

  local col = 1
  for _, text in ipairs(cmd_line) do
    self.breadcrumbs:set(1, col, text[1], text[2] and text[2]:gsub('WhichKey', '') or nil)
    col = col + vim.fn.strwidth(text[1])
  end

  if type(Config.options.user_hooks.breadcrumbs) == 'function' then
    self.breadcrumbs = Config.options.user_hooks.breadcrumbs(self.breadcrumbs, cmd_line, self.results)
  end
  return self.breadcrumbs
end

return render_breadcrumbs
