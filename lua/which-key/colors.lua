local Config = require('which-key.config')

local M = {}

-- stylua: ignore
local links = {
  -- [""]      = "Function",
  Key       = "Function",
  Separator = "Comment",
  Operator  = "Keyword",
  Group     = "Keyword",
  Multi     = "Keyword",
  Desc      = "Identifier",
  Float     = "NormalFloat",
  Value     = "Comment",
  Border    = "FloatBorder",
  Mode      = 'Special',
}

function M.setup()
  for k, v in pairs(links) do
    vim.api.nvim_set_hl(0, 'WhichKey' .. k, { link = v, default = true })
    if vim.tbl_contains(Config.options.mode_highlights, k:lower()) then
      for _, mode in pairs({ 'Normal', 'Insert', 'Command', 'Operator', 'Visual' }) do
        vim.api.nvim_set_hl(0, 'WhichKey' .. k .. mode, { link = v, default = true })
      end
    end
  end
end

return M
