local Util = require('which-key.util')
local Config = require('which-key.config')
local state = require('which-key.keys.state')
local keys_utils = require('which-key.keys.utils')

-- secret character that will be used to create <nop> mappings
local secret = 'Þ'

local M = {}

M.hooked = {}
M.hooked_auto = {}
M.hooked_nop = {}
M.hooked_fast = {}

function M.hook_id(prefix_n, mode, buf)
  return mode .. (buf or '') .. Util.t(prefix_n)
end

function M.is_hooked(prefix_n, mode, buf)
  return M.hooked[M.hook_id(prefix_n, mode, buf)]
end

function M.hook_del(prefix_n, mode, buf)
  local id = M.hook_id(prefix_n, mode, buf)
  M.hooked[id] = nil
  M.hooked_auto[id] = nil
  M.hooked_nop[id] = nil
  M.hooked_fast[id] = nil

  if buf then
    pcall(vim.api.nvim_buf_del_keymap, buf, mode, prefix_n)
    pcall(vim.api.nvim_buf_del_keymap, buf, mode, prefix_n .. secret)
  else
    pcall(vim.api.nvim_del_keymap, mode, prefix_n)
    pcall(vim.api.nvim_del_keymap, mode, prefix_n .. secret)
  end
end

function M.hook_add(prefix_n, mode, buf, secret_only)
  -- check if this trigger is blacklisted
  if state.blacklist[mode] and state.blacklist[mode][prefix_n] then
    return
  end
  -- don't hook numbers. See #118
  if tonumber(prefix_n) then
    return
  end
  -- don't hook to j or k in INSERT mode
  if mode == 'i' and (prefix_n == 'j' or prefix_n == 'k') then
    return
  end
  -- never hook q
  if mode == 'n' and prefix_n == 'q' then
    return
  end
  -- never hook into select mode
  if mode == 's' then
    return
  end
  -- never hook into operator pending mode
  -- this is handled differently
  if mode == 'o' then
    return
  end
  if Util.t(prefix_n) == Util.t('<esc>') then
    return
  end
  -- never hook into operators in visual mode
  if (mode == 'v' or mode == 'x') and state.operators[prefix_n] then
    return
  end

  -- Check if we need to create the hook
  if type(Config.options.triggers) == 'string' and Config.options.triggers ~= 'auto' then
    if Util.t(prefix_n) ~= Util.t(Config.options.triggers) then
      return
    end
  end
  if type(Config.options.triggers) == 'table' then
    local ok = false
    for _, trigger in pairs(Config.options.triggers) do
      if Util.t(trigger) == Util.t(prefix_n) then
        ok = true
        break
      end
    end
    if not ok then
      return
    end
  end

  local opts = { noremap = true, silent = true }
  local id = M.hook_id(prefix_n, mode, buf)
  local id_global = M.hook_id(prefix_n, mode)
  -- hook up if needed
  if not M.hooked[id] and not M.hooked[id_global] then
    local cmd = [[<cmd>lua require("which-key").start(%q, {mode = %q, auto = true})<cr>]]
    cmd = string.format(cmd, Util.t(prefix_n), mode)
    local mapmode = mode == 'v' and 'x' or mode
    -- map group triggers and nops
    if secret_only ~= true then
      opts.desc = 'which-key trigger:auto' .. ' (' .. mapmode .. ') ' .. prefix_n .. ' :' .. cmd
      M.hooked_auto[id] = true
      keys_utils.map(mapmode, prefix_n, cmd, buf, opts)
    end

    if not state.nowait[prefix_n] then
      -- nops are needed, so that WhichKey always respects timeoutlen
      opts.desc = 'which-key trigger:nop ' .. ' (' .. mapmode .. ') ' .. prefix_n .. ' :<nop>'
      M.hooked_nop[id] = true
      keys_utils.map(mapmode, prefix_n .. secret, '<nop>', buf, opts)
    else
      M.hooked_fast[id] = true
    end

    M.hooked[id] = true
  end
end

---@param node Node
function M.add_hooks(mode, buf, node, secret_only)
  if not node.mapping then
    node.mapping = { prefix = node.prefix_n, group = true, keys = Util.parse_keys(node.prefix_n) }
  end
  if node.prefix_n ~= '' and node.mapping.group == true and not node.mapping.cmd then
    -- first non-cmd level, so create hook and make all decendents secret only
    M.hook_add(node.prefix_n, mode, buf, secret_only)
    secret_only = true
  end
  for _, child in pairs(node.children) do
    M.add_hooks(mode, buf, child, secret_only)
  end
end

function M.is_hook(prefix, cmd)
  -- skip mappings with our secret nop command
  local has_secret = prefix:find(secret)
  -- skip auto which-key mappings
  local has_wk = cmd and cmd:find('which%-key') and cmd:find('auto') or false
  return has_wk or has_secret
end

return M
