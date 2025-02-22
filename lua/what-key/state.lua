local state = {
  disabled = false,
  loaded = false, -- once we loaded everything
  scheduled = false,
  background = false,
  load_start = nil,
  queue = {},
  buffers = {},
  loading = {},
}

return state
