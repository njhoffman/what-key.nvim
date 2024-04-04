---@meta

--# selene: allow(unused_variable)

---@class Keymap
---@field rhs string
---@field lhs string
---@field buffer number
---@field expr number
---@field lnum number
---@field mode string
---@field noremap number
---@field nowait number
---@field script number
---@field sid number
---@field silent number
---@field callback fun()|nil
---@field id string terminal keycodes for lhs
---@field desc string
---@field label string

---@class KeyCodes
---@field keys string
---@field internal string[]
---@field notation string[]

---@class MappingOptions basic attributes of keymap if it exists
---@field noremap boolean
---@field silent boolean
---@field nowait boolean
---@field expr boolean
---@field desc string

---@class MappingMetadata which-key specific fields not a part of regular keymap
---@field label? string manually specify the description output for the key
---@field name? string assigned to label and indicates this is a virtual grouping prefix
---@field plugin? string plugin associated with this keymap
---@field category? string category associated with this keymap
---
---@class Mapping
---@field meta MappingMetadata
---@field opts MappingOptions
---@field keys KeyCodes
---@field buf number
---@field group string indicates children exists: "operator, multi, prefix"
---@field label string the formatted description to display
---@field desc string
---@field prefix string
---@field cmd string if the keymap rhs is a string
---@field callback fun()|nil if the keymap rhs is a function
---@field mode? string
---@field preset? string name of loaded preset that contains lhs
---@field plugin string
---@field fn fun()

---@class MappingGroup
---@field mapping? Mapping
---@field mappings VisualMapping[]
---@field mode string
---@field prefix_i string
---@field prefix_n string
---@field buf number

---@class MappingTree
---@field mode string
---@field buf? number
---@field tree Tree

---@class VisualMapping : Mapping
---@field key string
---@field highlights table
---@field value string

---@class PluginItem
---@field key string
---@field label string
---@field value string
---@field cmd string
---@field highlights table

---@class PluginAction
---@field trigger string
---@field mode string
---@field label? string
---@field delay? boolean

---@class Plugin
---@field name string
---@field actions PluginAction[]
---@field run fun(trigger:string, mode:string, buf:number):PluginItem[]
---@field setup fun(wk, opts, Options)
