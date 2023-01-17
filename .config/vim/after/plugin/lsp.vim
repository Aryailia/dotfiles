" Integrate 'prabirshrestha/vim-lsp'

" ga: go annotation
nnoremap <unique> <buffer> ga <plug>(lsp-definition)
nnoremap <unique> <buffer> ge <plug>(lsp-document-diagnostics)
nnoremap <unique> <buffer> gr <plug>(lsp-references)
nnoremap <unique> <buffer> gt <plug>(lsp-type-definition)
nnoremap <unique> <buffer> gi <plug>(lsp-implementation)
nnoremap <unique> <buffer> gs <plug>(lsp-document-symbol-search)
nnoremap <unique> <buffer> gS <plug>(lsp-workspace-symbol-search)
nnoremap <unique> <buffer> [g <plug>(lsp-previous-diagnostic)
nnoremap <unique> <buffer> ]g <plug>(lsp-next-diagnostic)
nnoremap <unique> <buffer> g? <plug>(lsp-hover)
nnoremap <unique> <buffer> <leader>rn <plug>(lsp-rename)
"nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
"nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

"nnoremap <unique> <buffer> yod :let g:lsp_diagnostics_virtual_text_enabled = 1

" I find the error messages clutter the view too much
let g:lsp_diagnostics_virtual_text_enabled = 0




function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif

  let g:lsp_format_sync_timeout = 1000
  "autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

  " refer to doc to add more commands
endfunction


" See https://github.com/mattn/vim-lsp-settings/blob/master/settings/deno.vim

if executable('rustup')
  au User lsp_setup call lsp#register_server({
  \  'name': 'rust-analyzer',
  \  'cmd': {server_info->['rustup', 'run', 'nightly', 'rust-analyzer']},
  \  'allowlist': ['rust'],
  \})
endif

if executable('deno')
  au User lsp_setup call lsp#register_server({
  \  'name': 'deno',
  \  'cmd': { server_info->['deno', 'lsp']},
  \  'root_uri': { server_info->lsp#utils#path_to_uri(
  \     lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'package.json')
  \  )},
  \  'initialization_options': {
  \    'enable': v:true,
  \    'lint': v:true,
  \    'importMap': empty(lsp#utils#find_nearest_parent_file(lsp#utils#get_buffer_path(), 'import_map.json')) ? v:null : lsp#utils#find_nearest_parent_file(lsp#utils#get_buffer_path(), 'import_map.json'),
  \  },
  \  'allowlist': [
  \    'javascript', 'javascript.jsx', 'javascriptreact',
  \    'typescript', 'typescript.tsx', 'typescriptreact',
  \  ],
  \})
endif


augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
