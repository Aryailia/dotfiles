"let s:URI_UNRESERVED = '0-9A-Za-z\-_.~'
"let s:URI_NONPERCENT = s:URI_UNRESERVED . "'" . '!*();:@&=+$,/?#\[\]'
"let s:URI_DOMAIN = 'https\?://[' . s:URI_UNRESERVED . ']\(:[0-9]\+\)\?'
"let s:URI_ENCODED = s:URI_DOMAIN . '\([' . s:URI_NONPERCENT . ']\)\?'
"let s:URI_ENCODED = s:URI_ENCODED . '\|<' . s:URI_ENCODED . ']>'

let s:SQUARE_NEST0 = '[^\[\]]' . '\|\\\[' . '\|\\\]'
let s:SQUARE_NEST1 = s:SQUARE_NEST0 . '\|\[\(' . s:SQUARE_NEST0 . '\)*\]'
let s:SQUARE_NEST2 = s:SQUARE_NEST1 . '\|\[\(' . s:SQUARE_NEST1 . '\)*\]'
let s:INLINE_DESTINATION = '\('
  \ . '<\([^[ \f\n\r\t]]\|\\<\|\\>\)*>'
  \ . '\|[^ ]\+'
\ . '\)'
let s:INLINE_TITLE = '\('
  \ . '"\([^"]\|\\"\)*"'
  \ . "\\|'\\("  . "[^']" . "\\|\\\\'" . "\\)*'"
\ . '\)'

" DESTINATION gets priority over TITLE (ie. only one provided, then DESINATION)
" though this pattern does not need to do that
" First bit forces INLINE_LINK to not start with an escaped open square racket
let s:INLINE_LINK = '\\\@<!\[\(' . s:SQUARE_NEST2 . '\)*\]'
  \ . '([ \f\n\r\t]*' . s:INLINE_DESTINATION . '\?[ \f\n\r\t]*'
  \ . s:INLINE_TITLE . '\?[ \f\n\r\t]*'
\. ')'
let s:INLINE_LINK_MARK = '\[\(' . s:SQUARE_NEST2 . '\)*\]'
  \ . '([ \f\n\r\t]*\zs' . s:INLINE_DESTINATION . '\?\ze[ \f\n\r\t]*'
  \ . s:INLINE_TITLE . '\?[ \f\n\r\t]*'
\ . ')'


function! s:SubBuffer(buffer, head, tail)
  let l:section = getbufline(a:buffer, a:head[0], a:tail[0])
  let l:lastIndex = len(l:section) - 1
  let l:section[l:lastIndex] = l:section[l:lastIndex][:a:tail[1] - 1]
  let l:section[0] = l:section[0][a:head[1] - 1:]
  return join(l:section, "\n")
endfunction

function! s:GetMarkdownLinkAtCursor()
  let l:start = [line('.'), col('.')]
  let l:destination = ''
  " b for back, c for okay to be already on the match, W for no word wrap
  if search(s:INLINE_LINK, 'bcW') > 0
    let l:head = [line('.'), col('.')]
    call search(s:INLINE_LINK, 'ceW')
    let l:tail = [line('.'), col('.')]
    if l:head[0] <= l:start[0] && l:start[0] <= l:tail[0]
      \ && l:head[1] <= l:start[1] && l:start[1] <= l:tail[1]

      " Must call tail search before head search
      " Otherwise tail search finds the previous instance
      call search(s:INLINE_LINK_MARK, 'bceW')
      let l:tail = [line('.'), col('.')]
      call search(s:INLINE_LINK_MARK, 'bcW')
      let l:head = [line('.'), col('.')]

      " Strip the trailing parenthesis (happens on empty destination)
      " Strip the optional angle brackets
      " TODO: Deal with escaped angle brackets
      let l:destination = matchstr(s:SubBuffer(bufname('%'), l:head, l:tail),
        \ '<\zs.\{-\}\ze>)\?$\|^.\{-\}\ze)\?$')
    endif
  endif

  " TODO: Add link referencing
  " TODO: Add autolinks
  " TODO: Add footnotes

  " Restore original cursor position
  call cursor(l:start[0], l:start[1])

  return l:destination
endfunction

function! s:UrlDecode(uri)
  " TODO: Actually make this work properly
  let l:str = substitute(a:uri, '%20', ' ', 'g')
  return l:str
endfunction

let s:WHITE = '[ \f\n\r\t]'
let s:NONWHITE = '[^ \f\n\r\t]'
let s:ATX = ' \{0,3\}#\{1,6\}\('
  \ . '$\|'
  \ . ' \+\zs.\{-\}\ze *\( #\+ *\)\?$'
\ . '\)'

function! s:MoveCursor_JumpToAnchor(anchor)
  call cursor(1, 1)
  while matchstr(getline('.'), s:ATX) != a:anchor
    if search(s:ATX, 'W') == 0
      call cursor(1, 1)
      break
    endif
  endwhile
endfunction

function! MarkdownFollowLink()
  let l:destination = s:GetMarkdownLinkAtCursor()

  " Multiple hashes (#) is illegal, but browsers try to escape extra hashes
  " This means that everything up until the first hash will be the file
  let l:file = s:UrlDecode(matchstr(l:destination, '^[^#?]*'))
  let l:anchor = s:UrlDecode(matchstr(l:destination, '#\zs.*$'))

  " TODO: Add URL escaping
  if l:file != "" && l:file != expand('%')
    "write
    execute('edit ' . l:file)
  endif

  " Jump to anchor
  if l:anchor != ""
    call s:MoveCursor_JumpToAnchor(l:anchor)
  endif

  "echo [l:destination, l:file, l:anchor]
endfunction


nnoremap <silent> \zx :call GetMarkdownLink()<CR>

