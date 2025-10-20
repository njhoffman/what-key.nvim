local Text = require("what-key.text")

---@class Layout
---@field mapping Mapping
---@field items VisualMapping[]
---@field options Options
---@field text Text
---@field breadcrumbs Text
---@field title Text
---@field results MappingGroup
local Layout = {}
Layout.__index = Layout

---@param map_group MappingGroup
---@param options? Options
function Layout:new(map_group, options)
  local this = {
    results = map_group,
    mapping = map_group.mapping,
    items = map_group.children,
    text = Text:new(),
    breadcrumbs = Text:new(),
    title = Text:new(),
  }
  setmetatable(this, self)
  return this
end

function Layout:max_width(key)
  local max = 0
  for _, item in pairs(self.items) do
    if item[key] and Text.len(item[key]) > max then
      max = Text.len(item[key])
    end
  end
  return max
end

function Layout:make_title()
  return self.title
  -- require('what-key.layout.list')(self)
end

function Layout:make_list()
  return require("what-key.extensions.view-list.layout.list")(self)
end

function Layout:make_breadcrumbs(history)
  return require("what-key.extensions.view-list.layout.breadcrumbs")(self)
end

return Layout
