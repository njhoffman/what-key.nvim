local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local themes = require("telescope.themes")
local telescope_config = require("telescope.config").values

local display = require("telescope._extensions.what-key.display")
local generate = require("telescope._extensions.what-key.generate")

local M = {}
local default_opts = {}

M.setup = function(setup_config) end

local attach_mappings = function()
  return true
end

M.all = function(theme_opts, conf_opts)
  theme_opts = themes.get_dropdown(theme_opts)
  conf_opts = vim.tbl_deep_extend("force", default_opts, conf_opts or {})

  local lines, widths = generate.get_ok_keys()
  pickers
    .new(theme_opts, {
      prompt_title = "What-Keys",
      results_title = "Keys",
      finder = finders.new_table({
        results = lines,
        entry_maker = display.entry_maker(widths),
      }),
      -- previewer = _previewer.previewer.new(conf_opts),
      sorter = telescope_config.file_sorter(theme_opts),
      attach_mappings = attach_mappings,
    })
    :find()
end

M.todo = function(theme_opts, conf_opts)
  theme_opts = themes.get_dropdown(theme_opts)
  conf_opts = vim.tbl_deep_extend("force", default_opts, conf_opts or {})

  local lines, widths = generate.get_todo_keys()
  pickers
    .new(theme_opts, {
      prompt_title = "Todo What-Keys",
      results_title = "Keys",
      finder = finders.new_table({
        results = lines,
        entry_maker = display.entry_maker(widths),
      }),
      -- previewer = _previewer.previewer.new(conf_opts),
      sorter = telescope_config.file_sorter(theme_opts),
      attach_mappings = attach_mappings,
    })
    :find()
end

return M
