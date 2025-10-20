local M = {}

M.namespace = vim.api.nvim_create_namespace("WhatKey")

---@class Options
local defaults = {
  plugins = {
    marks = true, -- shows a list of your marks on ' and `
    registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
    -- No actual key bindings are created
    spelling = {
      enabled = true, -- enabling this will show WhatKey when pressing z= to select spelling suggestions
      suggestions = 20, -- how many suggestions should be shown in the list?
    },
  },
  -- add operators that will trigger motion and text object completion
  -- to enable all native operators, set the preset / operators plugin above
  operators = { gc = "Comments" },
  motions = {
    count = true,
  },
  -- each item can be 'name', {'name', opts } for builtin presets, or a user defined function
  presets = {
    "operators",
    "motions",
    "text_objects",
    "windows",
    "nav",
    "z",
    "g",
  },

  ignore_unnamed_groups = false,
  ignore_missing_desc = false,
  hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " }, -- hide mapping boilerplate
  ignored = {}, -- list of patterns to ignore complete key

  -- Functions/Lua Patterns for formatting the labels
  replace = {
    key = {
      function(key)
        return require("what-key.mapper").format_keys(key)
      end,
      { "<Space>", "SPC" },
    },
    desc = {
      { "<Plug>%(?(.*)%)?", "%1" },
      { "^%+", "" },
      { "<[cC]md>", "" },
      { "<[cC][rR]>", "" },
      { "<[sS]ilent>", "" },
      { "^lua%s+", "" },
      { "^call%s+", "" },
      { "^:%s*", "" },
    },
  },
  icons = {
    breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
    separator = "➜", -- symbol used between a key and it's label
    group = "+", -- symbol prepended to a group
    ellipsis = "…",
    -- set to false to disable all mapping icons,
    -- both those explicitly added in a mapping
    -- and those from rules
    mappings = true,
    --- See `lua/which-key/icons.lua` for more details
    --- Set to `false` to disable keymap icons from rules
    ---@type wk.IconRule[]|false
    rules = {},
    -- use the highlights from mini.icons
    -- When `false`, it will use `WhichKeyIcon` instead
    colors = true,
    -- used by key format
    keys = {
      Up = " ",
      Down = " ",
      Left = " ",
      Right = " ",
      C = "󰘴 ",
      M = "󰘵 ",
      D = "󰘳 ",
      S = "󰘶 ",
      CR = "󰌑 ",
      Esc = "󱊷 ",
      ScrollWheelDown = "󱕐 ",
      ScrollWheelUp = "󱕑 ",
      NL = "󰌑 ",
      BS = "󰁮",
      Space = "󱁐 ",
      Tab = "󰌒 ",
      F1 = "󱊫",
      F2 = "󱊬",
      F3 = "󱊭",
      F4 = "󱊮",
      F5 = "󱊯",
      F6 = "󱊰",
      F7 = "󱊱",
      F8 = "󱊲",
      F9 = "󱊳",
      F10 = "󱊴",
      F11 = "󱊵",
      F12 = "󱊶",
    },
  },

  key_labels = {
    -- override the label used to display some keys. It doesn't effect WK in any other way.
    -- For example:
    -- ["<space>"] = "SPC",
    -- ["<cr>"] = "RET",
    -- ["<tab>"] = "TAB",
  },
  --stylua: ignore
  mappings = {
    help_menu    = '<F6>',       -- binding to scroll down inside the popup
    toggle_debug = '<F5>',       -- show detailed keymapping information
    options_menu = '<F4>',       -- launch options menu
    launch_wk    = '<F3>',       -- launch what-key manually
    scroll_down  = '<C-S-Down>', -- binding to scroll down inside the popup
    scroll_up    = '<C-S-Up>',   -- binding to scroll up inside the popup
    page_down    = '<M-f>',      -- binding to scroll down inside the popup
    page_up      = '<M-b>',      -- binding to scroll up inside the popup
  },
  mappings_user = {},

  window = {
    border = "none", -- none, single, double, shadow
    position = "bottom", -- bottom, top
    margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
    padding = { 1, 2, 1, 2 }, -- extra window padding [top, right, bottom, left]
    winblend = 0, -- value between 0-100 0 for fully opaque and 100 for fully transparent
  },
  layout = {
    height = { min = 4, max = 25 }, -- min and max height of the columns
    width = { min = 20, max = 50 }, -- min and max width of the columns
    spacing = 3, -- spacing between columns
    align = "left", -- align columns left, center or right
    groups_first = true,
    children_count = true,
  },
  other_layouts = {},

  show_help = true, -- show a help message in the command line for using WhatKey
  show_keys = true, -- show the currently pressed key and its label as a message in the command line

  -- triggers = { blacklist = {}, nowait = {}, list = {},
  --     auto = { enabled = true, groups = true/false/'named',
  --     presets: true/false/{ 'operators', ' text_objects' } }
  triggers = "auto", -- automatically setup triggers
  -- triggers = {"<leader>"} -- or specifiy a list manually
  triggers_auto = {
    groups = true,
    presets = true,
  },
  -- list of triggers, where WhatKey should not wait for timeoutlen and show immediately
  triggers_nowait = {
    -- marks
    "`",
    "'",
    "g`",
    "g'",
    -- registers
    '"',
    "<c-r>",
    -- spelling
    "z=",
  },
  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhatKey
    -- this is mostly relevant for keymaps that start with a native binding
    i = { "j", "k" },
    v = { "j", "k" },
  },
  -- disable the WhatKey popup for certain buf types and file types.
  -- Disabled by deafult for Telescope
  disable = {
    buftypes = {},
    filetypes = {},
  },
  sorting = {
    priority = { "order", "group", "children", "name", "desc", "key" },
    direction = "desc", -- 'asc' or 'desc'
  },
  mode_highlights = {}, -- separator, group, desc float value, border, mode
  user_hooks = {
    list_pre = nil,
    list_post = nil,
    breadcrumbs = nil,
  },
  vimade_fade = false,
  debug = false,
}

---@type Options
M.options = {}

---@param options? Options
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
