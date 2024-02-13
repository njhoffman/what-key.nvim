local on_key = function(key)
  -- operators show as g @
  local isCmdlineSearch = vim.fn.getcmdtype():find('[/?]') ~= nil
  local mode = vim.api.nvim_get_mode().mode
  vim.dbglog(key, vim.fn.keytrans(key))
end
local setup = function()
  local ns = vim.api.nvim_create_namespace('which-key')
  vim.on_key(on_key, ns)
end

return { setup = setup }
