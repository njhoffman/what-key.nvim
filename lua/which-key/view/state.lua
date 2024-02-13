local state = {
  keys = nil,
  prev_keys = nil,
  mode = 'n',
  reg = nil,
  count = 0,
  internal = nil,
  timing = {
    keys_n = 0,
    keys_average = 0,
    show_n = 0,
    show_average = 0,
  },
  debug = {
    enabled = false,
    win = nil,
    buf = nil,
  },
  cursor = {
    row = 1,
    history = {},
  },
  history = {},
  win = nil,
  buf = nil,
  parent_buf = nil,
}
return state
