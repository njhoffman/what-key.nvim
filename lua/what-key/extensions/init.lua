-- example extension
return {
  'extension-name',
  {
    config = {},
    hooks = {},
    state = {},
    events = {
      -- on_mode, on_config, on_start
      on_render = function()
        print('Hello from extension')
      end,
      on_mode = {
        { after = { 'ext1', 'ext2' } },
        function()
          print('Hello from extension')
        end,
      },
    },
  },
}
