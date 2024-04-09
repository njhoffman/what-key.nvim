---@meta

--# selene: allow(unused_variable)

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
