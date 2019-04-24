" URI can come without schemes
"if exists(s:thenameofthispluginloaded)
"  finish
"endif

nnoremap <Leader>zx :call SelectNextURI()<CR>


" NOTE: Testing this  on vim files is really annoying because vim files do
" comments with double quotes
function! SelectNextURI()
  " Save original cursor position
  let l:origin = [line('.'), col('.')]

  " Build l:find from s:regexps. This FSM for all the searches
  let l:find = []
  for l:pattern in s:regexps
    call add(l:find, searchpos(l:pattern, 'cnW'))
  endfor

  let l:closest_index = s:FindClosest(l:find)
  let l:pattern = s:regexps[l:closest_index]
  let l:found = l:find[l:closest_index]
  let l:end = searchpos(l:pattern, 'cenW')

  " Doesn't really resolve properly
  let l:index = 0
  " If l:found[0] is 0, so is l:found[1] ([1, 1] is smallest, 0 only on errors)
  while 0 && l:found[0] > 0 && l:closest_index > 0 
      \ && ! filereadable(s:GetTextRange(l:found, l:end))
    let l:find[l:closest_index] = searchpos(l:pattern, 'W')
    let l:end = searchpos(l:pattern, 'cenW')
    if l:end[0] == 0 | let l:find[l:closest_index] = [0, 0] | endif

    let l:closest_index = s:FindClosest(l:find)
    let l:pattern = s:regexps[l:closest_index]

    let l:found = l:find[l:closest_index]
    if l:end[0] == 0 | call cursor(l:found[0], l:found[1]) | endif

    "echo l:found l:end
    "echo l:closest_index
    "echo s:GetTextRange(l:found, l:end)
    "echo filereadable(s:GetTextRange(l:found, l:end))
    "call input("Enter ")
  endwhile
  "echo l:found l:end
  "echo l:closest_index
  ""echo s:GetTextRange(l:found, l:end)
  "echo filereadable(s:GetTextRange(l:found, l:end))
  "  call cursor(l:origin[0], l:origin[1])
  "return


  if l:closest_index >= 0
    let l:pattern = s:regexps[l:closest_index]
    " Search from end to the beginning deals with \zs after quotes for
    " when searching s:double_quote and s:single_quote
    " Put cursor at the other end of the search
    call searchpos(l:pattern, 'eW')
    normal v
    call searchpos(l:pattern, 'bW')
    " Put cursor at the other end of the search
    normal o
  else
    call cursor(l:origin[0], l:origin[1])
  endif
endfunction


function! s:GetTextRange(start, end)
  let [l:row_start, l:col_start] = a:start
  let [l:row_end, l:col_end] = a:end
  let l:lines = getline(l:row_start, l:row_end)
  if len(l:lines) == 0
    return ''
  else
    let l:lines[0] = l:lines[0][l:col_start - 1:]
    let l:lines[-1] = l:lines[-1][: l:col_end - 1]
    return join(l:lines, "\n")
  endif
endfunction


" Alternative to using filereadable(), will match unreadable files and
" directories
function! s:FileExists(path)
  " Using expand because glob works from getcwd() which might be different
  " from the directory of the file (eg. vim 'directory/file.md')
  " Links in general will be relative to their file's directory
  " expand('%:p:h') returns '/' when working at root
  let l:path = expand('%:p:h') . '/'. a:path
  " TODO: Remove dots, multiple slashes, evaluate double dots?
  return ! empty(glob(l:path))
endfunction



function! s:FindClosest(list)
  let l:length = len(a:list)

  let l:closeIndex = -1
  let [l:closeRow, l:closeCol] = [0, 0]
  let l:index = 0

  while l:index < l:length
    let [l:r, l:c] =  a:list[l:index]
    if l:closeRow == 0 || r < l:closeRow || (r == l:closeRow && c < l:closeCol)
      let l:closeIndex = l:index
      let [l:closeRow, l:closeCol] =  a:list[l:closeIndex]
    endif
    let l:index += 1
  endwhile

  return l:closeRow == 0 ? -1 : l:closeIndex
endfunction


let s:double_quote = '\m\(^"\|[^\\]"\)\zs\(\([^"]*\|\\"\)*\)[^\\]\ze"'
let s:single_quote = "\\m'\\zs[^']\\+\\ze'"
"let s:unquoted = '\m\(\\\\\|\\ \|\\\n\|[^ \n]\)\+'
let s:unquoted = '\m\f\+'
"let s:path = s:double_quote . '\|' . s:single_quote . '\|' . s:unquoted



let s:link = '\m'

let s:username_character = '[-A-Za-z_]'
let s:password_character = '[-A-Za-z0-9_%_;=+.~#@?&/!;,]'
let s:hostname_character = '[-A-Za-z0-9%_]'
let s:pathname_character = s:password_character

" Scheme and login info, right now  everything optional
" If username given, then scheme given
" If password given, then username and scheme given
" Although \? supposedly is greedy, need soomething it will always find
" if the pattern is not in the first index of the file
"let s:link_regexp .= '\(https\?\|s\?ftp\)'
let s:link .= '\([A-Za-z]\+://'
let s:link .=   '\(' . s:username_character 
let s:link .=     '\(:' . s:password_character . '*\)\?'
let s:link .=   '@\)\?'
let s:link .= '\)\?'

" Domain name
let s:link .= '\(' . s:hostname_character . '\+\.\)\+'
let s:link .= s:hostname_character . '\+'

" Path
let s:link .= '\(/' . s:pathname_character . '*\)\?'

"let s:regexps = [s:link, s:double_quote, s:single_quote, s:unquoted]
"let s:regexps = [s:link, s:single_quote, s:unquoted]
let s:regexps = [s:link, s:unquoted]
"let s:regexps = [s:link]
