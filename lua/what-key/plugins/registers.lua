---@type Plugin

local M = {}

M.name = 'registers'

-- TODO: presets.registers
M.actions = {
  { trigger = '"', mode = 'n' },
  { trigger = '"', mode = 'v' },
  { trigger = '@', mode = 'n' },
  { trigger = '<c-r>', mode = 'i' },
  { trigger = '<c-r>', mode = 'c' },
}
M.opts = {}

-- function M.setup(_wk, _config, options)
--   for _, action in ipairs(M.actions) do
--     if not action.delay then
--       table.insert(options.triggers_nowait, action.trigger)
--     end
--   end
-- end
function M.setup(_, config, options)
  M.opts = options
end
-- function M.setup(_wk, _config, options)
--   for _, action in ipairs(M.actions) do
--     if not action.delay then
--       table.insert(options.triggers_nowait, action.trigger)
--     end
--   end
-- end

local insert_mapping = {
  ['<C-r><C-r>'] = "λ_insert a register's content literally",
  ['<C-r><C-o>'] = 'λ_like "<C-r><C-r>", but don\'t auto-indent',
  ['<C-r><C-p>'] = 'λ_like "<C-r><C-r>", but fix indent',
}

local command_same_as = {
  ['<C-r><C-r>'] = { '<C-r><C-o>' },
}

local command_mapping = {
  ['<C-r><C-r>'] = "λ_insert a register's content or Δobject literally",
}

M.registers = '*+"-:.%/#=_abcdefghijklmnopqrstuvwxyz0123456789'

local labels = {
  ['"'] = 'last deleted, changed, or yanked content',
  ['0'] = 'last yank',
  ['-'] = 'deleted or changed content smaller than one line',
  ['.'] = 'last inserted text',
  ['%'] = 'name of the current file',
  [':'] = 'most recent executed command',
  ['#'] = 'alternate buffer',
  ['='] = 'result of an expression',
  ['+'] = 'synchronized with the system clipboard',
  ['*'] = 'synchronized with the selection clipboard',
  ['_'] = 'black hole',
  ['/'] = 'last search pattern',
}

---@type Plugin
---@return PluginItem[]
function M.run(_trigger, _mode, _buf)
  local items = {}

  for i = 1, #M.registers, 1 do
    local key = M.registers:sub(i, i)
    local ok, value = pcall(vim.fn.getreg, key, 1)
    if not ok then
      value = ''
    end

    if value ~= '' then
      table.insert(items, { key = key, label = labels[key] or '', value = value })
    end
  end
  return items
end

return M
