local M = {}

M.name = 'marks'

M.actions = {
  { trigger = "'", mode = 'n' },
  { trigger = '`', mode = 'n' },
  { trigger = 'g`', mode = 'n' },
  { trigger = "g'", mode = 'n' },
}

-- function M.setup(_wk, _config, options)
--   for _, action in ipairs(M.actions) do
--     table.insert(options.triggers_nowait, action.trigger)
--   end
-- end

M.opts = {}
function M.setup(_wk, _config, options)
  M.opts = options
end

local normal_mapping = {
  ["''"] = 'Ξ_Δ to the first CHAR of the line where Δ was before the latest jump.',
  ["'("] = 'Ξ_Δ to the first CHAR on the line of the start of the current sentence',
  ["')"] = 'Ξ_Δ to the first CHAR on the line of the end of the current sentence',
  ["'<LT>"] = 'Ξ_Δ to the first CHAR of the line where highlighted area starts/started in the current buffer.',
  ["'>"] = 'Ξ_Δ to the first CHAR of the line where highlighted area ends/ended in the current buffer.',
  ["'["] = 'Ξ_Δ to the first CHAR on the line of the start of last operated text or start of put text',
  ["']"] = 'Ξ_Δ to the first CHAR on the line of the end of last operated text or end of put text',
  ["'{"] = 'Ξ_Δ to the first CHAR on the line of the start of the current paragraph',
  ["'}"] = 'Ξ_Δ to the first CHAR on the line of the end of the current paragraph',
  ['`('] = 'Ξ_Δ to the start of the current sentence',
  ['`)'] = 'Ξ_Δ to the end of the current sentence',
  ['`<LT>'] = 'Ξ_Δ to the start of the highlighted area',
  ['`>'] = 'Ξ_Δ to the end of the highlighted area',
  ['`['] = 'Ξ_Δ to the start of last operated text or start of putted text',
  ['`]'] = 'Ξ_Δ to the end of last operated text or end of putted text',
  ['``'] = 'Ξ_Δ to the position before latest jump',
  ['`{'] = 'Ξ_Δ to the start of the current paragraph',
  ['`}'] = 'Ξ_Δ to the end of the current paragraph',
}

local labels = {
  ['^'] = 'Last position of cursor in insert mode',
  ['.'] = 'Last change in current buffer',
  ['"'] = 'Last exited current buffer',
  ['0'] = 'In last file edited',
  ["'"] = 'Back to line in current buffer where jumped from',
  ['`'] = 'Back to position in current buffer where jumped from',
  ['['] = 'To beginning of previously changed or yanked text',
  [']'] = 'To end of previously changed or yanked text',
  ['<lt>'] = 'To beginning of last visual selection',
  ['>'] = 'To end of last visual selection',
}

---@type Plugin
---@return PluginItem[]
function M.run(_trigger, _mode, buf)
  local items = {}

  local marks = {}
  vim.list_extend(marks, vim.fn.getmarklist(buf))
  vim.list_extend(marks, vim.fn.getmarklist())

  for _, mark in pairs(marks) do
    local key = mark.mark:sub(2, 2)
    if key == '<' then
      key = '<lt>'
    end
    local lnum = mark.pos[2]

    local line
    if mark.pos[1] and mark.pos[1] ~= 0 then
      local lines = vim.fn.getbufline(mark.pos[1], lnum)
      if lines and lines[1] then
        line = lines[1]
      end
    end

    local file = mark.file and vim.fn.fnamemodify(mark.file, ':p:~:.')

    local value = string.format('%4d  ', lnum)
    value = value .. (line or file or '')

    table.insert(items, {
      key = key,
      label = labels[key] or file and ('file: ' .. file) or '',
      value = value,
      highlights = { { 1, 5, 'Number' } },
    })
  end
  return items
end

return M
