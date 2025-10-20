local Util = require("what-key.util")
local Config = require("what-key.config")
local Text = require("what-key.text")
local Logger = require("what-key.logger")

local view_utils = require("what-key.extensions.view-list.utils")
local state = require("what-key.extensions.view-list.state")

local get_dimensions = function(self)
  local win_width = vim.api.nvim_win_get_width(state.win)
  local canvas_width = view_utils.get_canvas_width()

  local max_key_width = self:max_width("key")
  local max_label_width = self:max_width("label")
  local max_value_width = self:max_width("value")
  local max_children = self:max_width("children")
  local max_children_width = max_children and Text.len("+" .. max_children + 1) or 0

  local intro_width = max_key_width + 2 + Text.len(Config.options.icons.separator) + Config.options.layout.spacing
  local max_width = max_label_width + intro_width + max_value_width + max_children_width
  if max_width > canvas_width then
    max_width = canvas_width
  end

  local column_width = max_width
  local bounds = view_utils.get_bounds()

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

  local offset_x = 0
  local columns_used = math.min(columns, math.ceil(#self.items / height))
  if columns_used < columns then
    if Config.options.layout.align == "right" then
      offset_x = (columns - columns_used) * column_width
    elseif Config.options.layout.align == "center" then
      offset_x = math.floor((columns - columns_used) * column_width / 2)
    end
  end

  return {
    offset_x = offset_x,
    height = height,
    columns = columns,
    max_width = max_width,
    max_value_width = max_value_width,
    max_label_width = max_label_width - 1,
    max_key_width = max_key_width,
    column_width = column_width,
  }
end

local render_key = function(item, max_key_width)
  local key = item.key or ""
  if key == "<lt>" then
    key = "<"
  end
  if key == Util.t("<esc>") then
    key = "<esc>"
  end
  -- key = string.gsub(key, "^<", ""):gsub(">$", "")
  if Text.len(key) < max_key_width then
    key = string.rep(" ", max_key_width - Text.len(key)) .. key
  end
  return key
end

local render_value = function(item, pos, dim)
  -- value = "  17    [Util.t(p_maps.scroll_down)]  = 'scroll_down',"
  -- order = 5, highlights = { [1] = { [1] = 1, [2] = 5, [3] = "Number" } },
  local ellipsis = Config.options.icons.ellipsis

  local value = item.value
  pos.start = pos.start + 1
  if Text.len(value) > dim.max_value_width then
    value = vim.fn.strcharpart(value, 0, dim.max_value_width - 2) .. ellipsis
  end
  return value
end

local render_label = function(item, dim)
  -- vim.dbglog("label", item.key, item.keys.notation, item.prefix)
  local label = item.label
  local ellipsis = Config.options.icons.ellipsis
  if Text.len(label) > dim.max_label_width then
    label = vim.fn.strcharpart(label, 0, dim.max_label_width - 1) .. ellipsis
  end

  local children = item.child_count or nil
  local hl = item.type == "operator" and "Operator" or item.group and "Group" or "Desc"
  if children then
    hl = item.type == "operator" and "Operator" or item.group and "Group" or "Multi"
    label = label
      .. string.rep(" ", dim.max_label_width - Text.len(label) - #tostring(children) + 1)
      .. " +"
      .. children
  end

  return label, hl
end

-- function Layout:make_list(win)
local render_list = function(self)
  if not view_utils.is_valid(state.buf, state.win) then
    Logger.debug("List not rendered (invalid buf/win) " .. tostring(state.buf) .. "/" .. tostring(state.win))
    return
  end

  -- self.items = Config.options.user_hooks.list_pre(self.items)
  local dim = get_dimensions(self)

  -- if height > bounds.height.max then height = bounds.height.max end

  local pos = { col = 1, row = 1, start = 1 }
  local pad = { top = Config.options.window.padding[3], left = Config.options.window.padding[4] }

  state.rows = {}
  for _, item in pairs(self.items) do
    table.insert(state.rows, item)
    pos.start = (pos.col - 1) * dim.column_width + Config.options.layout.spacing + dim.offset_x
    if dim.columns == 1 then
      pos.start = (pos.col - 1) * dim.column_width + dim.offset_x
    end
    if pos.col == 1 then
      pos.start = pos.start + pad.left
    end

    local key = render_key(item, dim.max_key_width)
    self.text:set(pos.row + pad.top, pos.start, key, "Key")
    pos.start = pos.start + Text.len(key) + 1

    self.text:set(pos.row + pad.top, pos.start, Config.options.icons.separator, "Separator")
    pos.start = pos.start + Text.len(Config.options.icons.separator) + 1

    if item.value then
      local value = render_value(item, pos, dim)
      self.text:set(pos.row + pad.top, pos.start, value, "Value")
      if item.highlights then
        for _, hl in pairs(item.highlights) do
          self.text:highlight(pos.row + pad.top, pos.start + hl[1] - 1, pos.start + hl[2] - 1, hl[3])
        end
      end
      pos.start = pos.start + dim.max_value_width + 2
    end

    local label, hl = render_label(item, dim)
    self.text:set(pos.row + pad.top, pos.start, label, hl)

    if pos.row % dim.height == 0 then
      pos.col = pos.col + 1
      pos.row = 1
    else
      pos.row = pos.row + 1
    end
  end

  -- self.text = Config.options.user_hooks.list_post(self.text)

  for _ = 1, pad.top, 1 do
    self.text:nl()
  end

  return self.text
end

return render_list
