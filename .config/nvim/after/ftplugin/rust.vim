let s:cmdline_prefix_regexp = '//run:'

function! Build()
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T cargo build
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:RunDefault()
  vertical T cargo run
endfunction

function! s:RunWithArguments(cmdline)
  execute('vertical T ' . a:cmdline)
endfunction

function! Run()
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! Lint()
  RustFmt
  ALELint
endfunction

let b:ale_lint_on_text_changed = 'never'
let b:ale_lint_on_insert_leave = 1
let b:ale_lint_on_save = 0
let b:ale_lint_on_enter = 0
let b:ale_rust_rls_config = {
  \ 'rust': {
    \ 'all_targets': 1,
    \ 'build_on_save': 1,
    \ 'clippy_preference': 'on',
  \ }
\ }
let b:ale_rust_rls_toolchain = ''
let b:ale_linters = {'rust': ['rls']}
"let b:ale_rust_rls_executable = 'rust-analyzer'
let b:ale_fixers = ['rustfmt']
