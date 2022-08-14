"syn keyword
"syn match
"

finish

" Already provided by vim by default, but default is without keepend
syn region  htmlCommentPart start="<!--" end="-->" keepend

" Starting ticks and ending ticks have to be the same
" Does not deal with must start with non-tick (needed to anchor) or with
" escaping
syn region  commonmarkInlineCode start="`\z(`*\)" end="\z1`"

hi commonmarkInlineCode ctermfg=cyan
