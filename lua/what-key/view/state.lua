local state = {
  keys = nil,
  prev_keys = nil,
  mode = 'n',
  reg = nil,
  count = 0,
  timing = {
    keys_n = 0,
    keys_average = 0,
    show_n = 0,
    show_average = 0,
  },
  parent_buf = nil,
  internal = {},
  history = {},
}
return state
