local wk = require('which-key')
local config = require('which-key.config')
local defaults = require('which-key.presets.defaults')

local presets = {}

local setup_mappings = function()
  for name, maps in pairs(presets) do
    for _, mode in ipairs(maps[1]) do
      if mode == 'no' then
        for op_key, op_label in pairs(maps[2]) do
          maps[2][op_key] = config.options.operators[op_key] or op_label
          config.options.operators[op_key] = maps[2][op_key]
        end
        mode = 'n'
      end
      wk.register(maps[2], { mode = mode, prefix = '', preset = name })
    end
    presets[name] = maps[2]
  end
end

local setup = function()
  for k, v in pairs(config.options.presets) do
    if type(v) == 'function' then
      presets[k] = v()
    elseif type(v) == 'table' then
      presets[k] = v
    elseif type(v) == 'string' then
      if defaults[v] then
        presets[v] = defaults[v]
      else
        vim.notify('No default setting found for ' .. v)
      end
    end
    if presets[k] and (#presets[k] ~= 2 or type(presets[k][1]) ~= 'table') then
      if defaults[k] then
        presets[k] = { defaults[k][1], presets[k] }
      else
        vim.notify('Preset misconfigured: ' .. k .. ' ' .. vim.inspect(presets[k]))
        presets[k] = nil
      end
    end
  end
  setup_mappings()
end

return { setup = setup, presets = presets }
