local state = {
  win = nil,
  buf = nil,
  debug = {
    enabled = false,
    win = nil,
    buf = nil,
  },
  cursor = {
    row = 1,
    callback = nil,
    history = {},
  },
}

return state
