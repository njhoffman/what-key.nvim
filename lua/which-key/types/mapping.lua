---@meta

--# selene: allow(unused_variable)

---@class Keymap the native fields of neovim keymap objects
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

---@class KeyCodes parsed from Keymap.lhs
---@field keys string
---@field internal string[]
---@field notation string[]

---@class MappingRegister which-key specific mapping fields from the register command
---@field label? string manually specify the description output for the key
---@field name? string assigned to label and indicates this is a virtual grouping prefix
---@field plugin? string plugin associated with this keymap
---@field category? string category associated with this keymap

---@class MappingOptions basic attributes from parsing keymap options
---@field noremap boolean
---@field silent boolean
---@field nowait boolean
---@field expr boolean
---@field desc string

---@class Mapping the mapping object built from Keymap from the above classes
---@field meta MappingRegister
---@field opts MappingOptions
---@field keys KeyCodes
---@field buf number
---@field group string indicates child maps exists: "operator, multi, prefix"
---@field child_count number total number of child mappings
---@field label string the formatted description to display
---@field desc string
---@field prefix string
---@field cmd string if the keymap rhs is a string
---@field callback fun()|nil if the keymap rhs is a function
---@field mode? string
---@field preset? string name of loaded preset that contains lhs
---@field plugin string
---@field fn fun()

---@class VisualMapping : Mapping
---@field key string
---@field highlights table
---@field value string

---@class MappingGroup
---@field mapping? Mapping
---@field children VisualMapping[]
---@field mode string
---@field prefix_i string
---@field prefix_n string
---@field buf number

---@class MappingTree
---@field mode string
---@field buf? number
---@field tree Tree
