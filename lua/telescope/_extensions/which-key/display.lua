local strings = require("plenary.strings")
local entry_display = require("telescope.pickers.entry_display")

local function mode_highlight(mode)
  if mode == "i" then
    return "Special"
  elseif mode == "n" then
    return "SpecialChar"
  elseif mode == "v" then
    return "Visual"
  else
    return "Normal"
  end
end

local entry_maker = function(widths)
  local width_items = {
    { width = widths.key },
    { width = widths.mode },
    { width = widths.def },
  }

  local displayer = entry_display.create({
    separator = " ▏",
    items = width_items,
  })

  local make_display = function(entry)
    return displayer({
      { strings.align_str(entry.value.key, widths.key, true), "TelescopeResultsOperator" },
      { entry.value.mode, mode_highlight(entry.value.mode) },
      { entry.value.def, "TelescopeResultsComment" },
    })
  end

  return function(opt)
    local entry = {
      display = make_display,
      value = {
        key = opt.key,
        mode = opt.mode,
        def = opt.def,
      },
      ordinal = string.format("%s %s %s", opt.key, opt.mode, opt.def),
    }
    return entry
  end
end

return {
  entry_maker = entry_maker,
}
