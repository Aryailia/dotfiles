function Run()
  silent !falkon --private-browsing --no-extensions --new-window
    \ "%" >/dev/null 2>&1&
endfunction

" https://www.w3.org/QA/2002/04/valid-dtd-list.html
inoremap <buffer> <LocalLeader>init
  \ <C-o>:setlocal paste<CR>
  \<!DOCTYPE html><CR>
  \<html lang="en"><CR>
  \<head><CR>
  \  <meta charset="UTF-8"><CR>
  \  <meta name="viewport" content="width=device-width, initial-scale=1.0"><CR>
  \  <meta http-equiv="X-UA-Compatible" content="ie=edge"><CR>
  \  <title>Title</title><CR>
  \  <link rel="stylesheet" href="src/style.css"><CR>
  \  <script type="text/javascript"></script><CR>
  \  <script type="text/javascript" src="src/app.js"></script><CR>
  \</head><CR>
  \<CR>
  \<body><CR>
  \</body><CR>
  \</html>
  \<C-o>:setlocal nopaste<CR>


