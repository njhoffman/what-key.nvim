local M = {}

M.name = "presets"

M.operators = {
  ["c"] = "↶,✝,§ delete text [into register x] and start insert",
  ["d"] = "↶,✝,§ delete text [into register x]",
  ["y"] = "✝,§ yank text [into register x]",
  ["~"] = "↶,§ if 'tildeop' on, switch case of text",
  ["!"] = "↶,§ filter text through the {filter} command",
  ["<LT>"] = "↶,§ shift lines one 'shiftwidth' leftwards",
  [">"] = "↶,§ shift lines one 'shiftwidth' rightwards",
  ["="] = "↶,§ filter lines through \"indent\"",
  ["gU"] = "↶,§ make text uppercase",
  ["gq"] = "↶,§ format text",
  ["gu"] = "↶,§ make text lowercase",
  ["gw"] = "↶,§ format text and keep cursor",
  ["g@"] = "§ call 'operatorfunc'",
  ["g~"] = "↶,§ swap case for text",
  ["zf"] = "§ create a fold for text",
  -- operator pending
  ["<C-v>"] = "'start blockwise Visual mode",
  ["V"] = "start linewise Visual mode  ",
  ["v"] = "start charwise Visual mode",
}

M.motions = {
  ["<C-b>"] = "⤨ scroll N screens Backwards",
  ["<C-f>"] = "⤨ scroll N screens Forward",
  ["<BS>"] = "⤨ same as \"h\"",
  ["<C-h>"] = "⤨ same as \"h\"",
  ["<Tab>"] = "⤨ go to N newer entry in jump list",
  ["<C-i>"] = "⤨ same as <Tab>",
  ["<NL>"] = "⤨ same as \"j\"",
  ["<C-j>"] = "⤨ same as \"j\"",
  ["<CR>"] = "⤨ cursor to the first CHAR N lines lower",
  ["<C-m>"] = "⤨ same as <CR>",
  ["<C-n>"] = "⤨ same as \"j\"",
  ["<C-o>"] = "⤨ go to N older entry in jump list",
  ["<C-p>"] = "⤨ same as \"k\"",
  ["<Space>"] = "⤨ same as \"l\"",
  ["#"] = "⤨ search backward for the Nth occurrence of the ident under the cursor",
  ["$"] = "⤨ cursor to the end of Nth next line",
  ["%"] = "⤨ find the next (curly/square) bracket on this line and go to its match, or go to matching comment bracket, or go to matching preprocessor directive.",
  -- ["{count}%"] = "⤨ go to N percentage in the file",
  -- ["'"] = "⤨ cursor to the first CHAR on the line with mark {a-zA-Z0-9}",
  -- ["''"] = "⤨ cursor to the first CHAR of the line where the cursor was before the latest jump.",
  -- ["'("] = "⤨ cursor to the first CHAR on the line of the start of the current sentence",
  -- ["')"] = "⤨ cursor to the first CHAR on the line of the end of the current sentence",
  -- ["'<LT>"] = "⤨ cursor to the first CHAR of the line where highlighted area starts/started in the current buffer.",
  -- ["'>"] = "⤨ cursor to the first CHAR of the line where highlighted area ends/ended in the current buffer.",
  -- ["'["] = "⤨ cursor to the first CHAR on the line of the start of last operated text or start of put text",
  -- ["']"] = "⤨ cursor to the first CHAR on the line of the end of last operated text or end of put text",
  -- ["'{"] = "⤨ cursor to the first CHAR on the line of the start of the current paragraph",
  -- ["'}"] = "⤨ cursor to the first CHAR on the line of the end of the current paragraph",
  ["("] = "⤨ cursor N sentences backward",
  [")"] = "⤨ cursor N sentences forward",
  ["*"] = "⤨ search forward for the Nth occurrence of the ident under the cursor",
  ["+"] = "⤨ same as <CR>",
  [","] = "⤨ repeat latest f, t, F or T in opposite direction N times",
  ["-"] = "⤨ cursor to the first CHAR N lines higher",
  ["/"] = "⤨ search forward for the Nth occurrence of {pattern}",
  ["/<CR>"] = "⤨ search forward for {pattern} of last search",
  ["0"] = "⤨ cursor to the first char of the line",
  [":"] = "⤨ start entering an Ex command",
  [";"] = "⤨ repeat latest f, t, F or T N times",
  ["?"] = "⤨ search backward for the Nth previous occurrence of {pattern}",
  ["?<CR>"] = "⤨ search backward for {pattern} of last search",
  ["B"] = "⤨ cursor N WORDS backward",
  ["E"] = "⤨ cursor forward to the end of WORD N",
  ["F"] = "⤨ cursor to the Nth occurrence of {char} to the left",
  ["G"] = "⤨ cursor to line N, default last line",
  ["H"] = "⤨ cursor to line N from top of screen",
  ["L"] = "⤨ cursor to line N from bottom of screen",
  ["M"] = "⤨ cursor to middle line of screen",
  ["N"] = "⤨ repeat the latest '/' or '?' N times in opposite direction",
  ["T"] = "⤨ cursor till after Nth occurrence of {char} to the left",
  ["W"] = "⤨ cursor N WORDS forward",
  ["^"] = "⤨ cursor to the first CHAR of the line",
  ["_"] = "⤨ cursor to the first CHAR N - 1 lines lower",
  -- ["`"] = "⤨ cursor to the mark {a-zA-Z0-9}",
  -- ["`("] = "⤨ cursor to the start of the current sentence",
  -- ["`)"] = "⤨ cursor to the end of the current sentence",
  -- ["`<LT>"] = "⤨ cursor to the start of the highlighted area",
  -- ["`>"] = "⤨ cursor to the end of the highlighted area",
  -- ["`["] = "⤨ cursor to the start of last operated text or start of putted text",
  -- ["`]"] = "⤨ cursor to the end of last operated text or end of putted text",
  -- ["``"] = "⤨ cursor to the position before latest jump",
  -- ["`{"] = "⤨ cursor to the start of the current paragraph",
  -- ["`}"] = "⤨ cursor to the end of the current paragraph",
  ["b"] = "⤨ cursor N words backward",
  ["e"] = "⤨ cursor forward to the end of word N",
  ["f"] = "⤨ cursor to Nth occurrence of {char} to the right",
  ["h"] = "⤨ cursor N chars to the left",
  ["j"] = "⤨ cursor N lines downward",
  ["k"] = "⤨ cursor N lines upward",
  ["l"] = "⤨ cursor N chars to the right",
  ["n"] = "⤨ repeat the latest '/' or '?' N times",
  ["t"] = "⤨ cursor till before Nth occurrence of {char} to the right",
  ["w"] = "⤨ cursor N words forward",
  ["{"] = "⤨ cursor N paragraphs backward",
  ["|"] = "⤨ cursor to column N",
  ["}"] = "⤨ cursor N paragraphs forward",
  ["<C-End>"] = "⤨ same as \"G\"",
  ["<C-Home>"] = "⤨ same as \"gg\"",
  ["<C-Left>"] = "⤨ same as \"b\"",
  ["<C-Right>"] = "⤨ same as \"w\"",
  ["<Down>"] = "⤨ same as \"j\"",
  ["<End>"] = "⤨ same as \"$\"",
  ["<Home>"] = "⤨ same as \"0\"",
  ["<Left>"] = "⤨ same as \"h\"",
  ["<Right>"] = "⤨ same as \"l\"",
  ["<S-Down>"] = "⤨ same as CTRL-F",
  ["<S-Left>"] = "⤨ same as \"b\"",
  ["<S-Right>"] = "⤨ same as \"w\"",
  ["<S-Up>"] = "⤨ same as CTRL-B",
  ["<Up>"] = "⤨ same as \"k\"",
  ["[#"] = "⤨ cursor to N previous unmatched #if, #else or #ifdef",
  ["['"] = "⤨ cursor to previous lowercase mark, on first non-blank",
  ["[("] = "⤨ cursor N times back to unmatched '('",
  ["[*"] = "⤨ same as \"[/\"",
  ["[`"] = "⤨ cursor to previous lowercase mark",
  ["[/"] = "⤨ cursor to N previous start of a C comment",
  ["[["] = "⤨ cursor N sections backward",
  ["[]"] = "⤨ cursor N SECTIONS backward",
  ["[c"] = "⤨ cursor N times backwards to start of change",
  ["[m"] = "⤨ cursor N times back to start of member function",
  ["[s"] = "⤨ move to the previous misspelled word",
  ["[z"] = "⤨ move to start of open fold",
  ["[{"] = "⤨ cursor N times back to unmatched '{'",
  ["]#"] = "⤨ cursor to N next unmatched #endif or #else",
  ["]'"] = "⤨ cursor to next lowercase mark, on first non-blank",
  ["])"] = "⤨ cursor N times forward to unmatched ')'",
  ["]*"] = "⤨ same as \"]/\"",
  ["]`"] = "⤨ cursor to next lowercase mark",
  ["]/"] = "⤨ cursor to N next end of a C comment",
  ["]["] = "⤨ cursor N SECTIONS forward",
  ["]]"] = "⤨ cursor N sections forward",
  ["]c"] = "⤨ cursor N times forward to start of change",
  ["]m"] = "⤨ cursor N times forward to end of member function",
  ["]s"] = "⤨ move to next misspelled word",
  ["]z"] = "⤨ move to end of open fold",
  ["]}"] = "⤨ cursor N times forward to unmatched '}'",
  ["g#"] = "⤨ like \"#\", but without using \"\\<\" and \"\\>\"",
  ["g$"] = "⤨ when 'wrap' off go to rightmost character of the current line that is on the screen; when 'wrap' on go to the rightmost character of the current screen line",
  -- ["g'{mark}"] = "⤨ like |'| but without changing the jumplist",
  -- ["g`{mark}"] = "⤨ like |`| but without changing the jumplist",
  ["g*"] = "⤨ like \"*\", but without using \"\\<\" and \"\\>\"",
  ["g,"] = "⤨ go to N newer position in change list",
  ["g0"] = "⤨ when 'wrap' off go to leftmost character of the current line that is on the screen; when 'wrap' on go to the leftmost character of the current screen line",
  ["g;"] = "⤨ go to N older position in change list",
  ["gD"] = "⤨ go to definition of word under the cursor in current file",
  ["gE"] = "⤨ go backwards to the end of the previous WORD",
  ["gN"] = "⤨,↶ find the previous match with the last used search pattern and Visually select it",
  ["g^"] = "⤨ when 'wrap' off go to leftmost non-white character of the current line that is on the screen; when 'wrap' on go to the leftmost non-white character of the current screen line",
  ["g_"] = "⤨ cursor to the last CHAR N - 1 lines lower",
  ["gd"] = "⤨ go to definition of word under the cursor in current function",
  ["ge"] = "⤨ go backwards to the end of the previous word",
  ["gg"] = "⤨ cursor to line N, default first line",
  ["gj"] = "⤨ like \"j\", but when 'wrap' on go N screen lines down",
  ["gk"] = "⤨ like \"k\", but when 'wrap' on go N screen lines up",
  ["gm"] = "⤨ go to character at middle of the screenline",
  ["gM"] = "⤨ go to character at middle of the text line",
  ["gn"] = "⤨,↶ find the next match with the last used search pattern and Visually select it",
  ["go"] = "⤨ cursor to byte N in the buffer",
  ["g<Down>"] = "⤨ same as \"gj\"",
  ["g<End>"] = "⤨ same as \"g$\"",
  ["g<Home>"] = "⤨ same as \"g0\"",
  ["g<Up>"] = "⤨ same as \"gk\"",
  ["zj"] = "⤨ move to the start of the next fold",
  ["zk"] = "⤨ move to the end of the previous fold",
}

M.objects = {
  ["a"] = { name = "around" },
  ["a\""] = "double quoted string",
  ["a'"] = "single quoted string",
  ["a("] = "same as ab",
  ["a)"] = "same as ab",
  ["a<LT>"] = "\"a <>\" from '<' to the matching '>'",
  ["a>"] = "same as a<",
  ["aB"] = "\"a Block\" from \"[{\" to \"]}\" (with brackets)",
  ["aW"] = "\"a WORD\" (with white space)",
  ["a["] = "\"a []\" from '[' to the matching ']'",
  ["a]"] = "same as a[",
  ["a`"] = "string in backticks",
  ["ab"] = "\"a block\" from \"[(\" to \"])\" (with braces)",
  ["ap"] = "\"a paragraph\" (with white space)",
  ["as"] = "\"a sentence\" (with white space)",
  ["at"] = "\"a tag block\" (with white space)",
  ["aw"] = "\"a word\" (with white space)",
  ["a{"] = "same as aB",
  ["a}"] = "same as aB",
  ["i"] = { name = "inside" },
  ["i\""] = "double quoted string without the quotes",
  ["i'"] = "single quoted string without the quotes",
  ["i("] = "same as ib",
  ["i)"] = "same as ib",
  ["i<LT>"] = "\"inner <>\" from '<' to the matching '>'",
  ["i>"] = "same as i<",
  ["iB"] = "\"inner Block\" from \"[{\" and \"]}\"",
  ["iW"] = "\"inner WORD\"",
  ["i["] = "\"inner []\" from '[' to the matching ']'",
  ["i]"] = "same as i[",
  ["i`"] = "string in backticks without the backticks",
  ["ib"] = "\"inner block\" from \"[(\" to \"])\"",
  ["ip"] = "\"inner paragraph\"",
  ["is"] = "\"inner sentence\"",
  ["it"] = "\"inner tag block\"",
  ["iw"] = "\"inner word\"",
  ["i{"] = "same as iB",
  ["i}"] = "same as iB",
}

---@param config Options
function M.setup(wk, opts, config)
  -- Use extra info instead of misc
  require("which-key.plugins.presets.extra")
  -- require("which-key.plugins.presets.misc").setup(wk, opts)

  -- Operators
  if opts.operators then for op, label in pairs(M.operators) do config.operators[op] = label end end

  -- Motions
  if opts.motions then
    wk.register(M.motions, { mode = "n", prefix = "", preset = true })
    wk.register(M.motions, { mode = "o", prefix = "", preset = true })
  end

  -- Text objects
  if opts.text_objects then wk.register(M.objects, { mode = "o", prefix = "", preset = true }) end
end

return M
