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
  options = options or Config.options
  local this = {
    results = mappings,
    mapping = mappings.mapping,
    items = mappings.mappings,
    options = options,
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

function Layout:get_bounds(_opts)
  local opts = _opts and _opts or self.options.layout
  return {
    width = {
      max = type(opts.width.max) == 'function' and opts.width.max() or opts.width.max,
      min = type(opts.width.min) == 'function' and opts.width.min() or opts.width.min,
    },
    height = {
      max = type(opts.height.max) == 'function' and opts.height.max() or opts.height.max,
      min = type(opts.height.min) == 'function' and opts.height.min() or opts.height.min,
    },
  }
end

function Layout:make_title()
  return self.title
  -- require('which-key.layout.list')(self)
end

function Layout:make_list(win)
  return require('which-key.layout.list')(self, win)
end

function Layout:make_breadcrumbs()
  return require('which-key.layout.breadcrumbs')(self)
end

return Layout
