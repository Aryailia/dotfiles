function ListUrls() abort
  let l:current_window_id = winnr()
  let l:cursor_x = line('.')
  let l:cursor_y = col('.')
  " just a big number
  let [l:dx, l:dy] = [0, 0]
  let l:target = 0

  let l:uri_scan = execute("write !uriscan.sh -f")
  let l:list = []
  let l:current_buffer_id = bufnr()
  let l:index = 1
  for line in split(l:uri_scan, '\n')
    let l:entry = split(line, '|')
    if len(l:entry) == 3
      let [l:x, l:y] = split(l:entry[0], ' ')

      if l:target <= 0 || abs(l:x - l:cursor_x) < l:dx
        \ || (abs(l:x - l:cursor_x) == l:dx && abs(l:y - l:cursor_y) <= l:dy)
        let l:dx = abs(l:x - l:cursor_x)
        let l:dy = abs(l:y - l:cursor_y)
        let l:target = l:index
      endif
      call add(l:list, {
        \ 'bufnr': bufnr(),
        \ 'lnum': l:x,
        \ 'col':  l:y,
        \ 'text': l:entry[2],
      \ })
      let l:index += 1
    endif
  endfor

  call setloclist(0, list)
  if l:target >= 1 | execute 'lfirst ' . l:target | endif
  lopen
  " 'lopen' moves to location list, return to the main window
  execute l:current_window_id . 'wincmd w'
endfunction


