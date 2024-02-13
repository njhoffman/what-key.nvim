local Config = require('which-key.config')
local Text = require('which-key.text')

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

---@param mappings MappingGroup
---@param options? Options
function Layout:new(mappings, options)
  local this = {
    results = mappings,
    mapping = mappings.mapping,
    items = mappings.mappings,
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
  -- require('which-key.layout.list')(self)
end

function Layout:make_list()
  return require('which-key.layout.list')(self)
end

function Layout:make_breadcrumbs(history)
  return require('which-key.layout.breadcrumbs')(self, history)
end

return Layout
