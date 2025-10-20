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
  local fname = nil
  local flines = {}
  -- if fn defined in string (ie loadstring) source is string
  -- if fn defined in file, source is file name prefixed with a `@´
  local Path = require("plenary.path")
  local filepath = info.source:gsub("@", "")

  if not Path:new(filepath):exists() then
    -- if the file does not exist, we cannot read it
    -- so we return an empty fname and flines
    return "<anon_nopath>", {}
  end
  local path = Path:new(filepath)
  for i, line in ipairs(path:readlines()) do
    if i == info.linedefined then
      fname = line
    end
    if i <= info.lastlinedefined and i >= info.linedefined then
      table.insert(flines, line)
    elseif i > info.lastlinedefined then
      break
    end
  end

  local state = require("what-key.keys.state")
  local fpath = (vim.fn.fnamemodify(info.short_src, ":p"):gsub("^./", ""):gsub(vim.env.HOME, "~"))
    .. ":"
    .. info.linedefined
    .. "-"
    .. info.lastlinedefined
  local f_name_orig = fname
  if not path:exists() then
    fname = "<anon_nopath:" .. fpath .. ">"
    table.insert(state._anon_no_path, { info = info, fname = fname, flines = flines })
  elseif not fname or ((fname:match("=") == nil) and (fname:match("function %S+%(") == nil)) then
    fname = "<anon:" .. fpath .. ">"
    table.insert(state._anon_no_func, { info = info, fname = fname, flines = flines })
  else
    local patterns = {
      { "function", "" }, -- remove function
      { "local", "" }, -- remove local
      { "[%s=]", "" }, -- remove whitespace and =
      { [=[%[["']]=], "" }, -- remove left-hand bracket of table assignment
      { [=[["']%]]=], "" }, -- remove right-ahnd bracket of table assignment
      { "%((.+)%)", "()" }, -- remove function arguments
      -- { "(.+)%.", "" }, -- remove TABLE. prefix if available
    }
    for _, tbl in ipairs(patterns) do
      fname = (fname:gsub(tbl[1], tbl[2])) -- make sure only string is returned
    end
  end
  return fname, flines
end

M.dump = function(opts)
  local state = require("what-key.keys.state")
  opts = opts or {}
  local categories = vim.tbl_deep_extend("force", {
    all = {},
    ok = {},
    todo = {},
    conflicts = {},
    anon = {},
    dupes = {},
    buffers = {},
    counts = {},
  }, opts.categories or {})

  local default_opts = {
    categories = vim.tbl_keys(categories),
    match = nil, -- nil or string to match lhs or rhs
    mode = nil, -- nil or mode character
    buf = nil, -- nil, true or buf number
  }

  opts = vim.tbl_deep_extend("force", default_opts, opts)

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
    if vim.tbl_contains(opts.categories, "counts") then
      if buf then
        categories.counts.buffers = categories.counts.buffers or {}
        categories.counts.buffers[buf] = categories.counts.buffers[buf] or {}
        categories.counts.buffers[buf][category] = type(categories.counts.buffers[buf][category]) == "number"
            and categories.counts.buffers[buf][category] + 1
          or 0
      else
        categories.counts[category] = type(categories.counts[category]) == "number" and categories.counts[category] + 1
          or 0
        if category == "all" or category == "ok" then
          categories.counts[category .. "_" .. mode] = type(categories.counts[category .. "_" .. mode]) == "number"
              and categories.counts[category .. "_" .. mode] + 1
            or 0
        end
      end
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

  local add_to_conflicts = function(msg)
    if check_category("conflicts") then
      table.insert(categories.conflicts, msg)
      add_to_counts("conflicts")
    end
  end

  local add_to_anon = function(fname, flines)
    if check_category("anon") then
      table.insert(categories.anon, { fname = fname, flines = flines })
      add_to_counts("anon")
    end
  end

  for _, anon in pairs(state._anon_no_func) do
    add_to_anon(anon.fname, anon.flines)
  end

  for _, anon in pairs(state._anon_no_path) do
    add_to_anon(anon.fname, anon.flines)
  end

  for _, tree in pairs(state.mappings) do
    -- TODO: is this needed?
    -- local Mapper = require('what-key.mapper')
    -- Mapper.update_keymaps(tree.mode, tree.buf)
    tree.tree:walk( ---@param node Node
      function(node)
        local count = 0
        for _ in pairs(node.children) do
          count = count + 1
        end

        local auto_prefix = not node.mapping or (node.mapping.group == true and not node.mapping.cmd)

        local prefix = node and node.mapping and node.mapping.prefix or ""
        local mode = node and node.mapping and node.mapping.mode or tree.mode

        if node.prefix_i ~= "" and count > 0 and not auto_prefix then
          local msg = ("conflicting keymap exists for mode %q %2s lhs: %q, rhs: %q"):format(
            tree.mode,
            count,
            prefix,
            node.mapping.cmd or " "
          )
          add_to_conflicts(msg)
        end

        if node.mapping then
          add_to_category("all", tree.buf, mode, prefix, node.mapping.label or node.mapping.cmd or "")

          if node.mapping.label and node.mapping.label ~= "" then
            add_to_category("ok", tree.buf, mode, prefix, node.mapping.label)
          else
            add_to_category("todo", tree.buf, mode, prefix, node.mapping.cmd or "")
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
