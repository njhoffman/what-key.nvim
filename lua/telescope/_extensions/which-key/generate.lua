local keys = require("which-key.keys")
local sort_by_mode = true

local sort_table = function(tbl)
  local mode_sort = { n = 1, i = 2, v = 3, o = 4 }
  if sort_by_mode then
    table.sort(tbl, function(a, b)
      if a.mode == b.mode then
        return a.key > b.key
      else
        return mode_sort[a.mode] < mode_sort[b.mode]
      end
    end)
  else
    table.sort(tbl, function(a, b)
      return a.key .. a.mode > b.key .. b.mode
    end)
  end
end

local get_ok_keys = function()
  local widths = { key = 0, mode = 0, def = 0 }
  local todo, ok, conflicts, dupes = keys.dump()

  sort_table(ok)
  local lines = {}
  for ok_mode, ok_keys in pairs(ok) do
    for ok_key, ok_def in pairs(ok_keys) do
      local line = { key = ok_key, mode = ok_mode, def = ok_def }
      table.insert(lines, line)
      for key, value in pairs(widths) do
        widths[key] = math.max(value, vim.fn.strdisplaywidth(line[key] or ""))
      end
    end
  end
  return lines, widths
end

local get_todo_keys = function()
  local widths = { key = 0, mode = 0, def = 0 }
  local todo, ok, conflicts, dupes = keys.dump()
  sort_table(todo)

  local lines = {}
  -- for _, conflict in ipairs(conflicts) do
  --   table.insert(lines, "conf: " .. conflict)
  -- end
  if sort_by_mode then
    table.sort(todo, function(a, b)
      return a.mode .. a.key < b.mode .. b.key
    end)
  else
    table.sort(todo, function(a, b)
      return a.key .. a.mode < b.key .. b.mode
    end)
  end

  for todo_mode, todo_keys in pairs(todo) do
    for todo_key, todo_def in pairs(todo_keys) do
      local line = { key = todo_key, mode = todo_mode, def = todo_def }
      table.insert(lines, line)
      for key, value in pairs(widths) do
        widths[key] = math.max(value, vim.fn.strdisplaywidth(line[key] or ""))
      end
    end
  end

  return lines, widths
end

return {
  get_todo_keys = get_todo_keys,
  get_ok_keys = get_ok_keys,
}
