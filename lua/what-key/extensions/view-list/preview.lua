local Range = {}

function Range.from_motion(motion, opts)
  -- Options handling:
  opts = opts or {}
  if opts.bufnr == nil then
    opts.bufnr = vim.api.nvim_get_current_buf()
  end
  if opts.contains_cursor == nil then
    opts.contains_cursor = false
  end
  if opts.user_defined == nil then
    opts.user_defined = false
  end

  -- Extract some information from the motion:
  --- @type 'a'|'i', string
  local scope, motion_rest = motion:sub(1, 1), motion:sub(2)
  local is_txtobj = scope == "a" or scope == "i"
  local is_quote_txtobj = is_txtobj and vim.tbl_contains({ "'", '"', "`" }, motion_rest)

  -- Capture the original state of the buffer for restoration later.
  local original_state = {
    winview = vim.fn.winsaveview(),
    regquote = vim.fn.getreg('"'),
    cursor = vim.fn.getpos("."),
    pos_lbrack = vim.fn.getpos("'["),
    pos_rbrack = vim.fn.getpos("']"),
    opfunc = vim.go.operatorfunc,
  }
  --- @type u.Range|nil
  local captured_range = nil

  vim.api.nvim_buf_call(opts.bufnr, function()
    if opts.pos ~= nil then
      opts.pos:save_to_pos(".")
    end

    _G.Range__from_motion_opfunc = function(ty)
      captured_range = Range.from_op_func(ty)
    end
    vim.go.operatorfunc = "v:lua.Range__from_motion_opfunc"
    vim.cmd({
      cmd = "normal",
      bang = not opts.user_defined,
      args = { "g@" .. motion },
      mods = { silent = true },
    })
  end)

  -- Restore original state:
  vim.fn.winrestview(original_state.winview)
  vim.fn.setreg('"', original_state.regquote)
  vim.fn.setpos(".", original_state.cursor)
  vim.fn.setpos("'[", original_state.pos_lbrack)
  vim.fn.setpos("']", original_state.pos_rbrack)
  vim.go.operatorfunc = original_state.opfunc

  if not captured_range then
    return nil
  end

  preview_motion = function()

    -- local opts = {
    --   bufnr = vim.api.nvim_get_current_buf(),
    --   contains_cursor = true,
    --   user_defined = true,
    -- }
    -- local range = Range.from_motion(vim.fn.getcmdline(), opts)
    -- if range == nil then
    --   return ""
    -- end
    -- return range:to_string()
  end

  -- Fixup the bounds:
  if
    -- I have no idea why, but when yanking `i"`, the stop-mark is
    -- placed on the ending quote. For other text-objects, the stop-
    -- mark is placed before the closing character.
    (is_quote_txtobj and scope == "i" and captured_range.stop:char() == motion_rest)
    -- *Sigh*, this also sometimes happens for `it` as well.
    or (motion == "it" and captured_range.stop:char() == "<")
  then
    captured_range.stop = captured_range.stop:next(-1) or captured_range.stop
  end
  if is_quote_txtobj and scope == "a" then
    captured_range.start = captured_range.start:find_next(1, motion_rest) or captured_range.start
    captured_range.stop = captured_range.stop:find_next(-1, motion_rest) or captured_range.stop
  end

  if opts.contains_cursor and not captured_range:contains(Pos.new(unpack(original_state.cursor))) then
    return nil
  end
  return captured_range
end

local M = {}
M.toggle_preview = function()
  state.debug.enabled = not state.debug.enabled
  if state.debug.enabled then
    state.cursor.callback = M.update
    M.show_debug()
  else
    M.hide_debug()
    state.cursor.callback = nil
  end
end

return M
