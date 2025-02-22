local M = {}

M.lookup = function(...)
  local results = {}
  for _, t in ipairs({ ... }) do
    for _, v in ipairs(t) do
      results[v] = v
    end
  end
  return results
end

M.get_anon_function = function(info)
  -- info.lastlinedefined, namewhat, source, nparams, short_src, currentline, func, what, nups,
  -- linedefined
  local Path = require('plenary.path')
  local fname
  -- if fn defined in string (ie loadstring) source is string
  -- if fn defined in file, source is file name prefixed with a `@´
  local path = Path:new((info.source:gsub('@', '')))
  if not path:exists() then
    -- table.insert(state._anon_no_path, { info.short_src, info.linedefined, fname })
    return '<_anon>'
  end
  for i, line in ipairs(path:readlines()) do
    if i == info.linedefined then
      fname = line
      break
    end
  end

  -- test if assignment or named function, otherwise anon
  if (fname:match('=') == nil) and (fname:match('function %S+%(') == nil) then
    -- table.insert(state._anon_no_func, { info.short_src, info.linedefined, fname })
    return '<anon>'
  else
    local patterns = {
      { 'function', '' }, -- remove function
      { 'local', '' }, -- remove local
      { '[%s=]', '' }, -- remove whitespace and =
      { [=[%[["']]=], '' }, -- remove left-hand bracket of table assignment
      { [=[["']%]]=], '' }, -- remove right-ahnd bracket of table assignment
      { '%((.+)%)', '' }, -- remove function arguments
      { '(.+)%.', '' }, -- remove TABLE. prefix if available
    }
    for _, tbl in ipairs(patterns) do
      fname = (fname:gsub(tbl[1], tbl[2])) -- make sure only string is returned
    end
    return fname
  end
end

M.dump = function(opts)
  local state = require('which-key.keys.state')
  opts = opts or {}
  local categories =
    { all = {}, ok = {}, todo = {}, conflicts = {}, dupes = {}, buffers = {}, counts = {} }

  local default_opts = {
    categories = vim.tbl_keys(categories),
    match = nil, -- nil or string to match lhs or rhs
    mode = nil, -- nil or mode character
    buf = nil, -- nil, true or buf number
  }

  opts = vim.tbl_deep_extend('force', default_opts, opts)

  local check_mode = function(mode)
    return opts.mode == nil or opts.mode == mode
  end

  local check_category = function(category)
    return vim.tbl_contains(opts.categories, category)
  end

  local check_buf = function(buf)
    return opts.buffer == nil or opts.buffer == buf
  end

  local add_to_counts = function(category, mode, buf)
    if vim.tbl_contains(opts.categories, 'counts') then
      if buf then
        categories.counts.buffers = categories.counts.buffers or {}
        categories.counts.buffers[buf] = categories.counts.buffers[buf] or {}
        categories.counts.buffers[buf][category] = type(categories.counts.buffers[buf][category])
              == 'number'
            and categories.counts.buffers[buf][category] + 1
          or 0
      else
        categories.counts[category] = type(categories.counts[category]) == 'number'
            and categories.counts[category] + 1
          or 0
        if category == 'all' or category == 'ok' then
          categories.counts[category .. '_' .. mode] = type(
            categories.counts[category .. '_' .. mode]
          ) == 'number' and categories.counts[category .. '_' .. mode] + 1 or 0
        end
      end
    end
  end

  local add_to_conflicts = function(msg)
    if check_category('conflicts') then
      table.insert(categories.conflicts, msg)
      add_to_counts('conflicts')
    end
  end

  local add_to_category = function(category, buf, mode, prefix, value)
    if check_category(category) and check_mode(mode) then
      if buf and check_buf(buf) then
        categories.buffers[buf] = categories.buffers[buf] or {}
        categories.buffers[buf][mode] = categories.buffers[buf][mode] or {}
        categories.buffers[buf][mode][prefix] = value
        add_to_counts(category, mode, buf)
      else
        categories[category][mode] = categories[category][mode] or {}
        categories[category][mode][prefix] = value
        add_to_counts(category, mode, buf)
      end
    end
  end

  for _, tree in pairs(state.mappings) do
    -- TODO: is this needed?
    -- local Mapper = require('which-key.mapper')
    -- Mapper.update_keymaps(tree.mode, tree.buf)
    -- vim.dbglog('tree: ' .. tree.mode .. ' ' .. tostring(tree.buf))
    tree.tree:walk( ---@param node Node
      function(node)
        local count = 0
        for _ in pairs(node.children) do
          count = count + 1
        end

        local auto_prefix = not node.mapping
          or (node.mapping.group == true and not node.mapping.cmd)

        local prefix = node and node.mapping and node.mapping.prefix or ''
        local mode = node and node.mapping and node.mapping.mode or tree.mode

        if node.prefix_i ~= '' and count > 0 and not auto_prefix then
          local msg = ('conflicting keymap exists for mode %q %2s lhs: %q, rhs: %q'):format(
            tree.mode,
            count,
            prefix,
            node.mapping.cmd or ' '
          )
          add_to_conflicts(msg)
        end

        if node.mapping then
          add_to_category(
            'all',
            tree.buf,
            mode,
            prefix,
            node.mapping.label or node.mapping.cmd or ''
          )

          if node.mapping.label and node.mapping.label ~= '' then
            add_to_category('ok', tree.buf, mode, prefix, node.mapping.label)
          else
            add_to_category('todo', tree.buf, mode, prefix, node.mapping.cmd or '')
          end
        end
      end
    )
  end

  -- local dupes = {}
  -- for _, dup in pairs(state.duplicates) do
  --   local msg = ''
  --   if dup.buf == dup.other.buffer then
  --     msg = 'duplicate keymap'
  --   else
  --     msg = 'buffer-local keymap overriding global'
  --   end
  --   msg = (msg .. ' for mode **%q**, buf: %d, lhs: **%q**'):format(
  --     dup.mode,
  --     dup.buf or 0,
  --     dup.prefix
  --   )
  --   table.insert(dupes, msg)
  --
  --   counts.dupes = type(counts.dupes) == 'number' and counts.dupes + 1 or 0
  --   -- vim.fn["health#report_info"](("old rhs: `%s`"):format(dup.other.rhs or ""))
  --   -- vim.fn["health#report_info"](("new rhs: `%s`"):format(dup.cmd or ""))
  -- end
  return categories
end

return M
