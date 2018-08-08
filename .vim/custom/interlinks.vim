" let s:html1 = '<\%(script|pre|style\)\%(\s|\n|>\)'
" let s:html2345 = '<!--|<?|<!\u|<![CDATA['
" let s:html6 = '\%(<|</\)\%(address|article|aside|base|basefont|blockquote|boddy|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul\)\%(\s|\n|/>>\)' 

  " \ 'header': '^ \{0,3}#\{1,6}\%( \+.*\)?',
  " \ 'header': '^ \{0,3}#\{1,6}\%( \+.*\)\?',
" let s:starter = {
"   \ 'header': '^ \{0,3}#\{1,6}',
"   \ 'indent_code': '^\%( \{4}| *\t\).\+',
"   \ 'fenced_code': '```',
"   \ 'html': '',
"   \ 'link_ref': '^ \{0,3}\[\]:',
"   \ 'footnote': '^ \{0,3}\%(\^\[]|\)',
"   \ 'blank': '^\s*$'
" \}
" let s:code_indent = '```'
" let s:block_quote = '> '

function! s:GetLinkAtIndex(text, targetIndex)
  let l:type1 = '\\\@<!\[.\{-}\\\@<!\](.\{-}\\\@<!)' " []()
  let l:type2 = '\\\@<!\[.\{-}\\\@<!\]\[.\{-}\\\@<!\]' " [][]
  let l:type3 = '\\\@<!\[.\{-}\\\@<!\]' " []
  let l:pattern = '\%(' . l:type1 . '\|' . l:type2 . '\|' . l:type3 . '\)'

  " Loop through finding next match until find one that contains a:targetIndex
  let l:length = strlen(a:text)
  let l:index = 0
  let l:matched = ''
  let l:tilldex = 0 " not inclusive of l:tilldex
  while 1
    let l:index = match(a:text, l:pattern, l:tilldex)
    let l:matched = matchstr(a:text, l:pattern, l:tilldex)
    let l:tilldex = l:index + strlen(l:matched)

    if l:index < 0 || l:index >= l:length | let l:matched = '' | break | endif
    if a:targetIndex >= l:index && a:targetIndex < l:tilldex | break | endif 
  endwhile
  " echo l:matched.','.a:targetIndex.','.l:index.','.l:tilldex.';'
  return [l:index, l:matched]
endfunction

function! s:ParseMarkdownLink(markdownLink)
  " Should lint
  " 1) if destination has <>, [^\_S<>]
  " 2) if destination no <>, no space/no control characters/no unescaped paren
  " unless parens are nested & balanced/
  " link titles can multiline but no blank line
  let l:link = matchstr(a:markdownLink, '\m\\\@<!\](\zs.*\\\@<!\ze)')
  let l:link = match(l:link, '\m\\\@<!#') == -1 ? l:link . '#' : l:link

  let l:file = matchstr(l:link, '^[^\%(\\\@<!#\)]*')
  let l:file = l:file == '' ? expand('%:t') : l:file
  let l:anchor = matchstr(l:link, '\m\\\@<!#\zs.*')
  return [l:file, tolower(l:anchor)]
endfunction

function! s:ParseFileAST(filename)
  let l:file = readfile(a:filename)
  let l:ast = []
  let l:row = 1
  for line in l:file
    if line =~ '\m^ \{0,3}#\{1,6}\%(\s+.*\)\?'
      call add(l:ast, { 'row': l:row, 'text': s:Anchorify(line) }) 
    endif
    let l:row += 1
  endfor
  return l:ast
  " return filter(l:file, "v:val =~ '" . '\m^ \{0,3}#\{1,6}\%(\s+.*\)\?' . "'")
endfunction

" let t:navigation_stack = []

function! FollowLink(path, anchor)
  execute 'edit ' . a:path
  let l:ast = s:ParseFileAST(a:path)
  for header in l:ast
    if header.text == a:anchor
      " Jump to the line
      execute header.row
      break
    endif
  endfor
endfunction

function! FollowBack()

endfunction

function! FollowCursorLink()
  let [l:index, l:link] = s:GetLinkAtIndex(getline('.'), col('.') - 1)
  let [l:file, l:anchor] = s:ParseMarkdownLink(l:link)
  let l:file = expand('%:p:h') . '/' . l:file
  call FollowLink(l:file, l:anchor)
endfunction

" function! SubChar(str, pos)
"   return matchstr(a:str, '\%' . a:pos . 'c.')
" endfunction

function! s:Anchorify(text)
  let l:opener = '\s*#\+' " First # that indicates it's a heading
  let l:main = '\s\+\(.\{-}\)' " Optional content
  let l:closer = '\s\+#\+' " Optional
  let l:rest = '\s\+\(.*\)'
  let l:header = substitute(a:text,
    \ '^'.l:opener.'\%('.l:main.'\%('.l:closer.'\%('.l:rest.'\)\?\)\?\)\?$',
    \ '\1 \2', '')
  let l:header = substitute(tolower(l:header), ' ', '-', 'g')
  return substitute(l:header, '\(.*\)-$', '\1', '')
endfunction

" function! Anchori()
"   let l:asdf = expand("<cWORD>")
" 
"   try
"     noautocmd execute "vimgrep #" . s:header_regexp . "#j %"
"   catch /^Vim\%((\a\+)\)\=:E480/ " No Match
"   endtry
" 
"   for d in getqflist()
"     echo 'lovely' d
"   endfor
" 
"   " echo getqflist()
" endfunction
