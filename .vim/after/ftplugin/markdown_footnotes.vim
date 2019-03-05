" Author: Aryailia
" 
" Vaguely inspired by https://github.com/derdennis/vim-markdownfootnotes/
"
" TODO:
" - evaluate if we want to enter insert mode after pane search
" - smarter cursor placement?
" - add support for multiple references to the same footnote
" - see if jumplist is affected and reset it after?
" - Add stars, chinese random ones
" - Make this into proper plugin wrapping with proper keybindings
" - Add setting for default pref

" BUG: This universally does not accept references that end with a colon
"      eg. asdf [^1]:
"      Definitions really only should be blocks at the beginning,
"      but that's annoying to deal with
" '.\{-1}' is a non-greedy number of '.' one or more
" ':\@!' means do not match things that end with ':'

"===============================================================================
" Constants
"===============================================================================
let s:DEF_REGEXP = '^ *\[\^[^[:space:]]\{-1,}\]:'
let s:CITE_REGEXP = '\[\^[^[:space:]]\{-1,}\]:\@!'
let s:TAG_REGEXP = '\[\^\zs[^[:space:]]\{-1,}\ze\]'
let s:DEF_CITE_DIFF = -2 " [0:s:DEF_CITE_DIFF], -2 means minus one char

let s:ROMAN_NUMERAL_SYMBOLS = [
  \'i', 'iv', 'v', 'ix', 'x', 'xl', 'l', 'xc', 'c', 'cd', 'd', 'cm', 'm']
let s:ROMAN_NUMERAL_VALUES = [
  \  1,    4,   5,    9,  10,   40,  50,  90,  100,  400, 500,  900,1000]

" For use in s:NumberToCustom()
let s:ROMAN_NUMERAL_LENGTH = len(s:ROMAN_NUMERAL_VALUES)

" For use in s:GetTagType()
let s:ROMAN_NUMERAL_LOWERS = '^[' . join(s:ROMAN_NUMERAL_SYMBOLS, '') . ']\+$'
let s:ROMAN_NUMERAL_UPPERS = toupper(s:ROMAN_NUMERAL_LOWERS)

"===============================================================================
" Main (global namespace callables)
"===============================================================================
function! FootnoteViewToggle()
  let l:window_count = winnr('$')
  " 'exists' for first run
  " 'winnr' in case closed main window so only one left
  " '!= -1 && win_gotoid' if opened a window and it's still openable
  if exists('b:MarkdownFootnote_WinId') &&
      \ (b:MarkdownFootnote_WinId != -1 && win_gotoid(b:MarkdownFootnote_WinId))
    if l:window_count > 1
      " Already called 'win_gotoid()'
      execute('close')
    endif
    let b:MarkdownFootnote_WinId = -1
  else
    call s:OpenSplit()
  endif
endfunction

"function! FixFootnotes(type)
"  let [l:row, l:col] = [line('.'), col('.')]
"  call cursor(1, 1)
"  call s:MutateSortTagsAfterCursor(1, a:type)
"  call cursor(l:row, l:col)
"endfunction

"===============================================================================
" Private Main Logic
"===============================================================================
function! s:OpenSplit()
  " Cursor on footnote tag
  let l:line = getline('.')
  let [l:pos, l:cite] = s:GetRegexpAtIndex(l:line, s:CITE_REGEXP, col('.') - 1)
  let l:row = s:FindRowOfDefFromCite(l:cite)
  if l:pos != -1
    " Find the definition and jump to it
    " Search from the end of the file
    if l:row != 0
      call s:SplitAndSetWinId()
      call cursor(l:row, 0)
      startinsert!
    else
      echo 'No note definition found'
    endif

  " Cursor on footnote definition (block unsupported)
  else|let l:def = matchstr(l:line, s:DEF_REGEXP)|if l:def != ''
    " 'n' do not move, only want to move if citation actually found
    " 'b' cause theoretically faster, 'w' in case citation is after
    " 'z' to avoid match on current line
    let l:cite_row = search(s:EscapeSearch(l:def[0:s:DEF_CITE_DIFF]), 'bnwz')
    " If found
    if l:cite_row != 0
      call s:SplitAndSetWinId()
      execute('normal! ' . l:cite_row . 'zt')
      execute('wincmd p')
    else
      echo 'No note citation found'
    endif

  " Update citations and insert the citation
  else
    let l:cite = '[^' . s:InsertCitation() . ']'
    call s:SplitAndSetWinId()
    call cursor(s:FindRowOfDefFromCite(l:cite), 0)
    startinsert!
  endif|endif
endfunction

function! s:MutateSortTagsAfterCursor(value, type)
  let [l:cursor_row, l:cursor_col] = [line('.'), col('.')]

  let [l:row, l:col] = [0, 0]
  let l:citations = []
  while 1
    let [l:row, l:col] = searchpos(s:CITE_REGEXP, 'W')
    if l:row == 0 && l:col == 0 | break | endif
    let [l:_, l:cite] = s:GetRegexpAtIndex(getline(l:row), s:CITE_REGEXP, l:col)
    let l:cite_tag = s:ExtractCiteTag(l:cite)
    let l:def_row = s:FindRowOfDefFromCite(l:cite)

    " Replace tags of the same type and that have definitions
    " Avoid false positive replacing
    if s:GetTagType(l:cite_tag) == a:type && l:def_row >= 1
      let l:citations += [[l:row, l:def_row, l:cite]]
    endif
  endwhile

  let l:new_tag = a:value + len(l:citations)
  for [l:cite_row, l:def_row, l:cite] in reverse(l:citations)
    let l:note_regexp = s:EscapeSearch(l:cite) .
      \ '/[^' . s:NumberToCustom(l:new_tag, a:type) . ']/'
    execute(l:cite_row . 's/' . l:note_regexp)
    execute(l:def_row . 's/' . l:note_regexp)
    let l:new_tag -= 1
  endfor
  call cursor(l:cursor_row, l:cursor_col)
endfunction

" Directly inserts a ref at cursor, does not check if cursor already on a ref
" s:GetSurroundingCiteTagsAtCursor() might be doing extra work as it factors
" cursor currently highlighting a ref or not
function! s:InsertCitation()
  let [l:prev, l:next] = s:GetSurroundingCiteTagsAtCursor()

  " Decide on the type of the new citation
  " TODO:let it equal the default
  let l:type = 'arabic_number'
  let l:value = 1
  if l:prev != ''
    let l:type = s:GetTagType(l:prev)
    let l:value = s:CustomToNumber(l:prev) + 1
  elseif l:next != ''
    let l:type = s:GetTagType(l:next)
    let l:value = s:CustomToNumber(l:next) - 1
  endif
  " TODO:if default_to_roman then choose roman numeral over alphabet
  let l:new_tag = s:NumberToCustom(l:value, l:type)

  " Increment all the relevant citations and definitions (ones after cursor)
  call s:MutateSortTagsAfterCursor(l:value, l:type)

  " Insert the citation at cursor
  let l:cursor_col = col('.')
  execute('s/\%#/[^' . l:new_tag . ']/')
  " Add three for the two brackets and the one caret
  call cursor(line('.'), l:cursor_col + strlen(l:new_tag) + 3)

  " Insert the definition
  " Prefer inserting before the one after because definitions might be blocks
  " (Though currently, we do not handle the block case and may never)
  let l:row = -1
  if l:next != ''
    let l:row = s:FindRowOfDefFromCite('[^' . l:next . ']') - 1
  elseif l:prev != ''
    let l:row = s:FindRowOfDefFromCite('[^' . l:prev . ']')
  endif
  let l:row = (l:row == -1) ? line('$') : l:row
  call append(l:row, '[^' . l:new_tag . ']: ')

  return l:new_tag
endfunction

" Searches around the current cursor position
" Returns a list
" Have to offset for the tag
" TODO: Check for when there are multiple citations on a single line
function! s:GetSurroundingCiteTagsAtCursor()
  " Move cursor to avoid finding the citation cursor is already on
  " Only necessary for the back search
  let [l:row, l:col] = [line('.'), col('.')]
  let [l:index, l:_] = s:GetRegexpAtIndex(getline(l:row), s:CITE_REGEXP, l:col)
  if l:index != -1 | call cursor(l:row, l:index + 1) | endif

  " Restore cursor, necessary if citation was under original cursor position
  " BUG: Vim bug, 'z' starts at col 0 contrary to documentation? (so not using)
  "      Also 'z' flag might no apply consistently with b applied, but unsure
  let [l:top_r, l:top_c] = searchpos(s:CITE_REGEXP, 'Wnb')
  if l:index != -1 | call cursor(l:row, l:col) | endif
  let [l:bot_r, l:bot_c] = searchpos(s:CITE_REGEXP, 'Wn')

  " Get the citation tags themselves
  let l:top = s:GetRegexpAtIndex(getline(l:top_r), s:CITE_REGEXP, l:top_c)
  let l:bot = s:GetRegexpAtIndex(getline(l:bot_r), s:CITE_REGEXP, l:bot_c)
  return [s:ExtractCiteTag(l:top[1]), s:ExtractCiteTag(l:bot[1])]
endfunction

"===============================================================================
" Helpers
"===============================================================================
function! s:SplitAndSetWinId()
  execute('belowright 4split')
  let b:MarkdownFootnote_WinId = win_getid()
endfunction

function! s:EscapeSearch(string)
  return substitute(a:string, '\ze[\\\^\[\]\-\/$~*?]', '\', 'g')
endfunction

function! s:ExtractCiteTag(citation)
  " return a:ref[2:-2] " Skip first two characters and last one character
  return matchstr(a:citation, s:TAG_REGEXP)
endfunction

function! s:FindRowOfDefFromCite(tag)
  return search('^ *' . s:EscapeSearch(a:tag) . ':', 'nw')
endfunction

function! s:GetTagType(val)
  if a:val =~ '^[0-9]\+$' | return 'arabic_number' | endif
  if a:val =~ s:ROMAN_NUMERAL_LOWERS | return 'roman_numeral_lower' | endif
  if a:val =~ s:ROMAN_NUMERAL_UPPERS | return 'roman_numeral_upper' | endif
  if a:val =~ '^[a-z]\+$' | return 'latin_alphabet_lower' | endif
  if a:val =~ '^[A-Z]\+$' | return 'latin_alphabet_upper' | endif
  return 'unknown'
endfunction

function! s:NumberToCustom(number, type)
  let l:num = a:number
  let l:out = ''

  " Error checking, do not 'return' so default behaviour takes over
  " Must be a number (0) and non-positive, or a string (1)
  if !((type(a:number) == 0 && a:number >= 1) || type(a:number) == 1)

  " Coerce to a number
  elseif a:type == 'arabic_number'
    return a:number + 0

  " Run through the array from largest to lowest values, and build up 'l:out'
  " Repeat handles the number of any single numeral to add (or not add)
  elseif a:type == 'roman_numeral_lower' || a:type == 'roman_numeral_upper'
    let l:index = s:ROMAN_NUMERAL_LENGTH

    while l:index > 0
      let l:index = l:index - 1
      let l:times = l:num / s:ROMAN_NUMERAL_VALUES[l:index]

      let l:num = l:num % s:ROMAN_NUMERAL_VALUES[l:index]
      let l:out = l:out . repeat(s:ROMAN_NUMERAL_SYMBOLS[l:index], l:times)
    endwhile

    return (a:type == 'roman_numeral_lower') ? l:out : toupper(l:out)

  " Simple change of base to base-26, use nr2char to convert digit set
  " 97 is 'a', 65 is 'A' in ASCII
  elseif a:type == 'latin_alphabet_lower' || a:type == 'latin_alphabet_upper'
    let l:ascii_offset = (a:type == 'latin_alphabet_lower') ? 96 : 64
    while l:num > 0
      let l:remainder = l:num % 26
      let l:num = l:num / 26

      let l:out = nr2char(l:ascii_offset + l:remainder) . l:out
    endwhile
    return l:out

  " Do not 'return' so default behaviour takes over
  elseif a:type == 'unknown'
  endif
  return '?'
endfunction

function! s:CustomToNumber(custom)
  let l:type = s:GetTagType(a:custom)

  " Already what we want
  if l:type == 'arabic_number'
    return a:custom

  " Parse from the right-most, least-significant to the left, parsing
  " conditionally two digits at a time, falling back to parsing one if invalid
  elseif l:type == 'roman_numeral_lower' || l:type == 'roman_numeral_upper'
    let l:custom = tolower(a:custom)
    let l:i = strlen(a:custom)
    let l:out = 0
    while l:i > 0
      let l:i -= 1

      let l:pair = index(s:ROMAN_NUMERAL_SYMBOLS, l:custom[l:i - 1 : l:i])
      let l:single = index(s:ROMAN_NUMERAL_SYMBOLS, l:custom[l:i])

      " If two digits were matched, then move the 'l:i' down one
      " In the case were 'l:custom[l:i - 1 : l:1]' is a single character
      " hence 'l:pair == l:single', taking the 'l:pair' branch adds the same
      " value as taking the 'l:single' branch so there is no problem
      if l:pair >= 0
        let l:out += s:ROMAN_NUMERAL_VALUES[l:pair]
        " Does not matter if this 'l:i' goes negative
        let l:i -= 1
      else
        let l:out += s:ROMAN_NUMERAL_VALUES[l:single]
      endif
    endwhile
    return l:out
    
  " Start from the right-most, lowest-significant digits and add increasing
  " powers of 26. Force them both lower and upper to the same case 
  elseif l:type == 'latin_alphabet_lower' || l:type == 'latin_alphabet_upper'
    let l:power = 1
    let l:out = 0
    for l:digit in reverse(split(toupper(a:custom), '\zs'))
      let l:out = l:out + (char2nr(l:digit) - 64) * l:power
      let l:power = l:power * 26
    endfor
    return l:out
  endif
  
  return '?'
endfunction

" match('a', 'a', 0) will match, 0 start means begin search at that index
" Additionally, match returns an index
" So a:index should be an index, cursor('.') is a position (index + 1)
function! s:GetRegexpAtIndex(string, pattern, index)
  let [l:pos, l:found, l:start] = [-1, '', 0]
  while 1
    let l:pos = match(a:string, a:pattern, l:start)
    let l:found = matchstr(a:string, a:pattern, l:start)
    let l:start = l:pos + strlen(l:found)

    if l:pos == -1 |          let l:found = '' | break | endif
    if l:pos <= a:index && a:index < l:start   | break | endif 
  endwhile
  return [l:pos, l:found]
endfunction
