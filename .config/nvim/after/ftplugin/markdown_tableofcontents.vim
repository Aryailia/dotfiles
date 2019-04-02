" Test with folding

finish

let s:ATX_HEADER = '^ \{0,3\}\zs#\{1,6\}'
let s:ATX = '^ \{0,3\}#\{1,6\}\('
  \ . '$\|'
  \ . ' \+\zs.\{-\}\ze *\( #\+ *\)\?$'
\ . '\)'


function! MarkdownTableOfContents()
  let l:origin = [line('.'), col('.')]
  call cursor(1, 1)

  let l:toc_line_number = 0
  let l:headings = []
  let l:line_number = search(s:ATX, 'cW')
  while l:line_number != 0
    let l:line = getline('.')
    let l:content = matchstr(l:line, s:ATX)
    call add(l:headings, [len(matchstr(l:line, s:ATX_HEADER)), l:content])
    if l:content =~ '^Table of Contents$\|^TOC$'
      let l:toc_line_number = l:line_number
    endif
    let l:line_number = search(s:ATX, 'W')
  endwhile

  " Add table of contents h1 if necessary as well
  let l:last = 1
  let l:index = [0]
  let l:toc = []
  if l:toc_line_number == 0
    let l:toc = ['# Table of Contents']
    let l:last = 1
  else
    let l:last = len(l:headings[0][0])
  endif
  for [level, content] in l:headings
    if level < l:last
      call remove(l:index, -1)
    elseif level > l:last
      call add(l:index, 0)
    endif
    let l:index[-1] += 1
    call add(l:toc, join(index, '.') . '. ' . content)
    let l:last = level
  endfor
  call append(l:toc_line_number, l:toc)

  call cursor(l:origin[0], l:origin[1])
  echo [l:toc_line_number, l:toc]
endfunction

nnoremap <silent> \zt :call MarkdownTableOfContents()<CR>
" Test with folding
