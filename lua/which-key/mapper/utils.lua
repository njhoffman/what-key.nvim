local state = require('which-key.keys.state')

local M = {}

M.dump = function()
  local all = {}
  local ok = {}
  local todo = {}
  local conflicts = {}
  local counts = {}

  for _, tree in pairs(state.mappings) do
    -- Mappings.update_keymaps(tree.mode, tree.buf)
    tree.tree:walk( ---@param node Node
      function(node)
        local count = 0
        for _ in pairs(node.children) do
          count = count + 1
        end
        local auto_prefix = not node.mapping or (node.mapping.group == true and not node.mapping.cmd)
        if node.prefix_i ~= '' and count > 0 and not auto_prefix then
          local msg = ('conflicting keymap exists for mode %q %2s lhs: %q, rhs: %q'):format(
            tree.mode,
            count,
            node.mapping.prefix,
            node.mapping.cmd or ' '
          )
          table.insert(conflicts, msg)
          counts.conflicts = type(counts.conflicts) == 'number' and counts.conflicts + 1 or 0
          -- conflicts[tree.mode] = conflicts[tree.mode] or {}
          -- conflicts[tree.mode][node.mapping.prefix] = node.children
        end

        if node.mapping then
          all[tree.mode] = all[tree.mode] or {}
          all[tree.mode][node.mapping.prefix] = node.mapping.label or node.mapping.cmd or ''
          counts.all = type(counts.all) == 'number' and counts.all + 1 or 0

          if node.mapping.label then
            ok[tree.mode] = ok[tree.mode] or {}
            todo[tree.mode] = todo[tree.mode] or {}
            ok[tree.mode][node.mapping.prefix] = node.mapping.label
            todo[tree.mode][node.mapping.prefix] = nil
            counts.ok = type(counts.ok) == 'number' and counts.ok + 1 or 0
            counts['ok_' .. tree.mode] = type(counts['ok_' .. tree.mode]) == 'number' and counts['ok_' .. tree.mode] + 1
              or 0
          elseif not ok[node.mapping.prefix] then
            todo[tree.mode] = todo[tree.mode] or {}
            todo[tree.mode][node.mapping.prefix] = node.mapping.cmd or ''
            counts.todo = type(counts.todo) == 'number' and counts.todo + 1 or 0
            counts['todo_' .. tree.mode] = type(counts['todo_' .. tree.mode]) == 'number'
                and counts['todo_' .. tree.mode] + 1
              or 0
          end
        end
      end
    )
  end

  local dupes = {}
  for _, dup in pairs(state.duplicates) do
    local msg = ''
    if dup.buf == dup.other.buffer then
      msg = 'duplicate keymap'
    else
      msg = 'buffer-local keymap overriding global'
    end
    msg = (msg .. ' for mode **%q**, buf: %d, lhs: **%q**'):format(dup.mode, dup.buf or 0, dup.prefix)
    table.insert(dupes, msg)

    counts.dupes = type(counts.dupes) == 'number' and counts.dupes + 1 or 0
    -- vim.fn["health#report_info"](("old rhs: `%s`"):format(dup.other.rhs or ""))
    -- vim.fn["health#report_info"](("new rhs: `%s`"):format(dup.cmd or ""))
  end

  return {
    todo = todo,
    ok = ok,
    conflicts = conflicts,
    dupes = dupes,
    all = all,
    counts = counts,
  }
end

return M
