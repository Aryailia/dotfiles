function! s:Build() abort
  write
  vertical T compile.sh --temp % ; exit
endfunction

function! s:Run() abort
  let l:path = $TMPDIR . '/' . expand('%:t:r') . '.pdf'
  if filereadable(l:path)
    call s:Build()
  endif
  call system('handle.sh --gui "' . l:path . '"')
endfunction

"function! Lint()
"endfunction

function! GetPersonalInfo(key) abort
  let l:file = $DOTENVIRONMENT . "/name.yml"
  let l:entry = system("sed -n '/^" . a:key . ":/p' \"" . l:file . '"')
  let l:entry = substitute(l:entry, '\m^.*:\s*"', "", "")
  return l:entry[0:-3] " Remove two characters: sed's newline and closing quote
endfunction

" Snippets

" Homework (CJK fonts, name etc. above title, A4 margins)
inoremap <buffer> <LocalLeader>inithw
  \ <C-o>:setlocal paste<CR>
  \\documentclass[10.5pt,twoside,a4paper]{article}<CR>
  \\usepackage{xeCJK}<CR>
  \\setmainfont{Noto Serif CJK SC}<CR>
  \\setCJKmainfont{Noto Serif CJK SC}<CR>
  \<CR>
  \\usepackage[margin=2.5cm]{geometry}<CR>
  \\setlength{\parindent}{2em}  % Formal CJ[K?] indented by two full-widths<CR>
  \<CR>
  \\author{ <C-r>=GetPersonalInfo('name_s')<CR>}<CR>
  \\title{  title}<CR>
  \\date{<CR>
  \  <C-r>=GetPersonalInfo('year_s')<CR>\\<CR>
  \  subject\\<CR>
  \  %\today<CR>
  \}<CR>
  \<CR>
  \\begin{document}<CR>
  \<CR>
  \\makeatletter  % enable use of \@ commands<CR>
  \\begin{flushright}      \@author \\ \@date  \end{flushright}<CR>
  \\begin{center}\LARGE{}  \@title\\[3em]      \end{center}  % 3+1 newlines<CR>
  \\makeatother   % back to default<CR>
  \<CR>
  \START<CR>
  \<CR>
  \\end{document}<CR>
  \<C-o>:setlocal nopaste<CR>

let b:Build = function('<SID>Build')
let b:Run = function('<SID>Run')
