local Util = require('which-key.util')
local Config = require('which-key.config')
local Text = require('which-key.text')

-- function Layout:make_list(win)
local render_list = function(self, win)
  local win_width = vim.api.nvim_win_get_width(win)
  local canvas_width = win_width - self.options.window.padding[2] - self.options.window.padding[4]

  if type(Config.options.user_hooks.list_pre) == 'function' then
    self.items = Config.options.user_hooks.list_pre(self.items)
  end

  local max_key_width = self:max_width('key')
  local max_label_width = self:max_width('label')
  local max_value_width = self:max_width('value')

  local intro_width = max_key_width + 2 + Text.len(self.options.icons.separator) + self.options.layout.spacing
  local max_width = max_label_width + intro_width + max_value_width
  if max_width > canvas_width then
    max_width = canvas_width
  end

  local column_width = max_width
  local bounds = self:get_bounds()

  if column_width > bounds.width.max then
    column_width = bounds.width.max
  end
  if column_width < bounds.width.min then
    column_width = bounds.width.min
  end

  if max_value_width == 0 then
    if column_width > bounds.width.max then
      column_width = bounds.width.max
    end
    if column_width < bounds.width.min then
      column_width = bounds.width.min
    end
  else
    max_value_width = math.min(max_value_width or win_width, math.floor((column_width - intro_width) / 2))
  end

  local columns = math.floor(win_width / column_width)
  max_label_width = column_width - (intro_width + max_value_width)
  local height = math.ceil(#self.items / columns)
  if height < bounds.height.min then
    height = bounds.height.min
  end
  -- if height > bounds.height.max then height = bounds.height.max end

  local col = 1
  local row = 1
  local pad_top = self.options.window.padding[3]
  local pad_left = self.options.window.padding[4]

  local columns_used = math.min(columns, math.ceil(#self.items / height))
  local offset_x = 0
  if columns_used < columns then
    if self.options.layout.align == 'right' then
      offset_x = (columns - columns_used) * column_width
    elseif self.options.layout.align == 'center' then
      offset_x = math.floor((columns - columns_used) * column_width / 2)
    end
  end

  for _, item in pairs(self.items) do
    local parts = {}
    local start = (col - 1) * column_width + self.options.layout.spacing + offset_x
    if col == 1 then
      start = start + pad_left
    end
    local key = item.key or ''
    if key == '<lt>' then
      key = '<'
    end
    if key == Util.t('<esc>') then
      key = '<esc>'
    end
    if Text.len(key) < max_key_width then
      key = string.rep(' ', max_key_width - Text.len(key)) .. key
    end

    table.insert(parts, { row + pad_top, start, key, '' })
    self.text:set(row + pad_top, start, key, '')
    start = start + Text.len(key) + 1

    self.text:set(row + pad_top, start, self.options.icons.separator, 'Separator')
    start = start + Text.len(self.options.icons.separator) + 1

    if item.value then
      local value = item.value
      start = start + 1
      if Text.len(value) > max_value_width then
        value = vim.fn.strcharpart(value, 0, max_value_width - 2) .. ' …'
      end
      self.text:set(row + pad_top, start, value, 'Value')
      if item.highlights then
        for _, hl in pairs(item.highlights) do
          self.text:highlight(row + pad_top, start + hl[1] - 1, start + hl[2] - 1, hl[3])
        end
      end
      start = start + max_value_width + 2
    end

    local label = item.label
    if Text.len(label) > max_label_width then
      label = vim.fn.strcharpart(label, 0, max_label_width - 2) .. ' …'
    end

    local children = item.children and tonumber(item.children) or nil
    if children then
      label = label .. ' +' .. children
      -- vim.dbglog(item.prefix, item.label, children)
    end
    self.text:set(row + pad_top, start, label, item.group and 'Group' or 'Desc')

    if row % height == 0 then
      col = col + 1
      row = 1
    else
      row = row + 1
    end
  end

  if type(Config.options.user_hooks.list_post) == 'function' then
    self.text = Config.options.user_hooks.list_post(self.text)
  end

  for _ = 1, self.options.window.padding[3], 1 do
    self.text:nl()
  end

  return self.text
end

return render_list
