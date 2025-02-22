local state = require('which-key.keys.state')

local M = {}

function M.check_health()
  vim.health.report_start('WhichKey: checking conflicting keymaps')
  for _, tree in pairs(state.mappings) do
    M.update_keymaps(tree.mode, tree.buf)
    tree.tree:walk( ---@param node Node
      function(node)
        local count = 0
        for _ in pairs(node.children) do
          count = count + 1
        end

        local auto_prefix = not node.mapping or (node.mapping.group == true and not node.mapping.cmd)
        if node.prefix_i ~= '' and count > 0 and not auto_prefix then
          local msg = ('conflicting keymap exists for mode **%q**, lhs: **%q**'):format(tree.mode, node.mapping.prefix)
          vim.fn['health#report_warn'](msg)
          local cmd = node.mapping.cmd or ' '
          vim.health.report_info(('rhs: `%s`'):format(cmd))
        end
      end
    )
  end
  for _, dup in pairs(state.duplicates) do
    local msg = ''
    if dup.buf == dup.other.buffer then
      msg = 'duplicate keymap'
    else
      msg = 'buffer-local keymap overriding global'
    end
    msg = (msg .. ' for mode **%q**, buf: %d, lhs: **%q**'):format(dup.mode, dup.buf or 0, dup.prefix)
    if dup.buf == dup.other.buffer then
      vim.health.report_error(msg)
    else
      vim.health.report_warn(msg)
    end
    vim.health.report_info(('old rhs: `%s`'):format(dup.other.rhs or ''))
    vim.health.report_info(('new rhs: `%s`'):format(dup.cmd or ''))
  end
end

return M
