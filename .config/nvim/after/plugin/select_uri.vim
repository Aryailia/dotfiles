" URI can come without schemes
"if exists(s:thenameofthispluginloaded)
"  finish
"endif

noremap <unique> <Plug>SelectNextURI :call <SID>SelectNextURI()<CR>

function! s:SelectNextURI()
  " Save original cursor position
  let [l:originRow, l:originCol] = [line('.'), col('.')]

  let [l:pos, l:closestIndex] =
    \ s:FindClosestReadablePatternBefore(s:regexps, searchpos(s:link, 'cnW'))

  if l:closestIndex >= 0
    call cursor(l:pos[0], l:pos[1])
    call s:SelectSearchPattern((s:regexps + [s:link])[l:closestIndex])
  else " Nothing found so just reset cursor position
    call cursor(l:originRow, l:originCol)
  endif
endfunction

" noremap <unique> <C-m>0 :call DebugSelectURI(0)<CR>
" noremap <unique> <C-m>1 :call DebugSelectURI(1)<CR>
" noremap <unique> <C-m>2 :call DebugSelectURI(2)<CR>
" noremap <unique> <C-m>3 :call DebugSelectURI(3)<CR>
" vnoremap <C-m>0 <Esc>:call DebugSelectURI(0)<CR>
" vnoremap <C-m>1 <Esc>:call DebugSelectURI(1)<CR>
" vnoremap <C-m>2 <Esc>:call DebugSelectURI(2)<CR>
" vnoremap <C-m>3 <Esc>:call DebugSelectURI(3)<CR>
"
" noremap <unique> <C-m> :call DebugSelectURI(1)<CR>
" function! DebugSelectURI(type)
"   call s:MaybeHasAnchorPathExists('Table')
"   "call s:FindClosestReadablePatternBefore([s:simple_path], [100, 100])
"   "call s:FindClosestReadablePatternBefore(s:regexps, [100, 100])
"   "call s:SelectSearchPattern(s:regexps[a:type])
" endfunction

" Searches for all the patterns in list a:patternList from cursor till a:limit
" Returns -1 if limit is [0, x] and no pattern was found
" Intended for a:limit to also be the result of a searchpos
function! s:FindClosestReadablePatternBefore(patternList, limit)
  let [l:cursorX, l:cursorY] = [line('.'), col('.')]
  let l:limitIndex = len(a:patternList)

  let l:posList = []
  for a in a:patternList
    call add(l:posList, [l:cursorX, l:cursorY - 1])
  endfor
  call add(l:posList, a:limit)

  let l:posIndex = l:limitIndex  " Value to return if non of a:patternList found
  while 1
    let l:posIndex = s:MinPosition(l:posList)  " Ignores [0, 0] (search fails)
    if l:posIndex < 0 || l:posIndex >= l:limitIndex | break | endif
    let l:pattern = a:patternList[l:posIndex]

    call cursor(l:posList[l:posIndex][0], l:posList[l:posIndex][1])
    let l:posList[l:posIndex] = searchpos(l:pattern, 'W')
    let l:val = s:TextRange(l:posList[l:posIndex], searchpos(l:pattern, 'cenW'))

    "echo 'Debug the regexps:' l:val
    if s:MaybeHasAnchorPathExists(l:val) | break | endif
  endwhile
  " l:posIndex == -1 when all l:posList and a:limit are [0, x] (not found)
  return [l:posList[l:posIndex], l:posIndex]
endfunction


function! s:SelectSearchPattern(pattern)
  " Search from end to the beginning deals with \zs after quotes for
  " when searching s:double_quote and s:single_quote
  " Put cursor at the other end of the search
  call searchpos(a:pattern, 'eW')
  normal! v
  call searchpos(a:pattern, 'bW')
    " Put cursor at the other end of the search
  normal! o
endfunction


function! s:TextRange(a, b)
  let l:order = s:MinPosition([a:a, a:b])
  let [l:row_start, l:col_start] = (l:order == 0) ? a:a : a:b
  let [l:row_end, l:col_end] = (l:order == 0) ? a:b : a:a
  let l:lines = getline(l:row_start, l:row_end)
  if len(l:lines) == 0
    return ''
  else
    " Remove end first before remove beginning if l:row_start == l:row_end
    let l:lines[-1] = l:lines[-1][0: l:col_end - 1] 
    let l:lines[0] = l:lines[0][l:col_start - 1:]
    return join(l:lines, "\n")
  endif
endfunction


" Essentially filereadable(), will match unreadable files and directories
" Will also check both with and without a hastag (think html anchors)
"   (i.e. Checks 'as.md#df' checks both 'as.md#df' and 'as.md')
" but not the validity of the hashtag itself ('#df' might not exist in 'as.md')
function! s:MaybeHasAnchorPathExists(path)
  " Using expand because glob works from getcwd() which might be different
  " from the directory of the file (eg. vim 'directory/file.md')
  " Links in general will be relative to their file's directory
  " expand('%:p:h') returns '/' when working at root
  let l:sanitisedPath = substitute(a:path, '\m\*', '\\*', 'g')
  let l:splitPathByHash = split(l:sanitisedPath, '#', 1)
  let l:basedir = expand('%:p:h')

  let l:path1 = l:basedir . '/' . l:sanitisedPath
  let l:path2 = l:basedir . '/' . join(l:splitPathByHash[0:-2], '#')
  return (len(l:splitPathByHash) > 1)
    \ ? ! empty(glob(l:path1)) || ! empty(glob(l:path2))
    \ : ! empty(glob(l:path1))
endfunction



" Will ignore [0, x] and [x, 0] positions as these are invalid
" Returns -1 if no position is found
function! s:MinPosition(list)
  let l:length = len(a:list)

  let l:closeIndex = -1
  let [l:closeRow, l:closeCol] = [0, 0]
  let l:index = 0

  while l:index < l:length
    let [l:r, l:c] =  a:list[l:index]
    " s:FindClosestReadablePatternBefore() relies on no check l:closeCol == 0
    if l:closeRow == 0 || r < l:closeRow || (r == l:closeRow && c < l:closeCol)
      let l:closeIndex = l:index
      let [l:closeRow, l:closeCol] =  a:list[l:closeIndex]
    endif
    let l:index += 1
  endwhile

  return l:closeRow == 0 ? -1 : l:closeIndex
endfunction


let s:double_quote = '\m\C\(^"\|[^\\]"\)\zs\(\([^"]*\|\\"\)*\)[^\\]\ze"'
let s:single_quote = '\m\C''\zs[^'']\+\ze'''
"let s:unquoted = '\m\C\(\\\\\|\\ \|\\\n\|[^ \n]\)\+'
let s:unquoted = '\m\C\f\+'
"let s:path = s:double_quote . '\|' . s:single_quote . '\|' . s:unquoted

" This should be the general simple use case
"let s:file_character='[^\n ''"]'
"let s:file_separator = '-\n ''"!@$%^*-+\|;:,.<>?'
let s:path_separator = ' \n''"(){}[\]'
let s:simple_path = '\m\C'
  \ . '\([' . s:path_separator . ']\|^\)'
  \ .  '\zs\([^' . s:path_separator. ']\|\\ \)\+\ze'
  \ . '\([' . s:path_separator . ']\|$\)'



let s:link = '\m\C'

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

" This should be looking for paths
"let s:regexps = [s:double_quote, s:single_quote, s:unquoted]
"let s:regexps = [s:single_quote, s:unquoted]
"let s:regexps = [s:unquoted]
let s:regexps = [s:simple_path]
