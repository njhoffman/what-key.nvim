command! -nargs=* WhatKey lua require('what-key').start_command(<f-args>)
command! WhatKeyBackground lua require('what-key').toggle_background()
