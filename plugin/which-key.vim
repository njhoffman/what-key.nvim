command! -nargs=* WhichKey lua require('which-key').start_command(<f-args>)
command! WhichKeyBackground lua require('which-key').toggle_background()
