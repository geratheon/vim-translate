" translate.vim - Quickly translate a word
" Maintainer:   Jonas Kuball <jkuball@tzi.de>
" Version:      0.4

if exists("g:loaded_translate") || !executable("curl") || &cp
  finish
endif
let g:loaded_translate = 1

let g:translate_vars = [
      \   [ "g:translate_src",      '"en"' ],
      \   [ "g:translate_dst",      '"de"' ],
      \   [ "g:translate_backend",  '"dict.cc"' ],
      \   [ "g:translate_backends", '{}' ],
      \   [ "g:translate_format",   '"{index}: {dst} [{src}]"' ]
      \  ]

for [var, default] in g:translate_vars
  if !exists(var)
    exec 'let ' . var . ' = ' . default
  endif
endfor

let g:translate_backends["dict.cc"] = "translate#backends#dictcc"

function! s:Translate(word, invert)
  " Get the translation with the current backend
  let result = ""
  try
    exec 'let result = ' . g:translate_backends[g:translate_backend] . '(a:word, a:invert)'
  catch
    echohl WarningMsg | echo v:exception | echohl None
    return
  endtry

  let translations = []
  let index = 1
  for [srcword, dstword] in result
    call add(translations, substitute(substitute(substitute(g:translate_format,
          \ '{index}', index, ""),
          \ '{src}', srcword, ""),
          \ '{dst}', dstword, ""))
    let index = index + 1
  endfor

  " Let the user decide which translation he wants to use
  call insert(translations, "Select one:", 0)
  let index = inputlist(translations)
  try
    if !index
      throw 1
    endif
    " Put the translation below the cursor
    exec 'put =result[index -1][1]'
  catch
    echohl WarningMsg | echo "\nNothing inserted." | echohl None
  endtry
endfunction

command! -nargs=1 -bang Translate :call s:Translate(<f-args>, <bang>0)

" vim:set et sw=2
