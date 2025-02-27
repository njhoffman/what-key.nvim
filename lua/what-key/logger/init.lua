-- local utils = require('what-key.logger.utils')
local modules = {
  require("what-key.logger.mods.mapper"),
  require("what-key.logger.mods.format"),
}

--  󰞷 󰡱 ∅ 󰐕 

local debug_flag = true
local get_logger = function(level)
  local _logger = require("logger").init("whatkey")
  return function(msg, ...)
    if level == "trace" then
      if debug_flag then
        _logger:trace(msg, ...)
      end
    elseif level == "debug" then
      if debug_flag then
        _logger:debug(msg, ...)
      end
    elseif level == "info" then
      if debug_flag then
        _logger:info(msg, ...)
      end
    elseif level == "warn" then
      _logger:warn(msg, ...)
      vim.notify(msg, vim.log.levels.WARN, { title = "WhatKey" })
    elseif level == "error" then
      _logger:error(msg, ...)
      vim.notify(msg, vim.log.levels.ERROR, { title = "WhatKey" })
    end
  end
end

local logger = {
  trace = get_logger("trace"),
  debug = get_logger("debug"),
  info = get_logger("info"),
  warn = get_logger("warn"),
  error = get_logger("error"),
  utils = require("what-key.logger.utils"),
}

function logger.enable_debug()
  debug_flag = true
end

function logger.disable_debug()
  debug_flag = false
end

function logger.log(...)
  vim.dbglog(...)
end

for _, module in ipairs(modules) do
  module.init(logger)
  for _, name in ipairs(vim.tbl_keys(module)) do
    if name ~= "init" then
      logger[name] = module[name]
    end
  end
end

return logger
