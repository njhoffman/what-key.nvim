local wk = require('which-key')
local config = require('which-key.config')
local defaults = require('which-key.presets.defaults')

local presets = {}

local setup_mappings = function()
  for k, v in pairs(presets) do
    for _, m in ipairs(v[1]) do
      if m == 'no' then
        for op_key, op_label in pairs(v[2]) do
          config.options.operators[op_key] = op_label
        end
      else
        wk.register(v[2], { mode = m, prefix = '', preset = k })
      end
    end
    presets[k] = v[2]
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
