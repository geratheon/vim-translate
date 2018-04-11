" translate.vim - Quickly translate a word
" Maintainer:   Jonas Kuball <jkuball@tzi.de>
" Version:      0.1

if exists("g:loaded_translate") || !executable("curl") || &cp
  finish
endif
let g:loaded_translate = 1

if !exists("g:translate_src")
  let g:translate_src = "en"
endif

if !exists("g:translate_dst")
  let g:translate_dst = "de"
endif

function! s:Translate(invert, word)
  let l:translate_src = g:translate_src
  let l:translate_dst = g:translate_dst
  if a:invert
    let l:translate_src = g:translate_dst
    let l:translate_dst = g:translate_src
  endif

  " TODO: urlencode a:word (see tpopes unimpaired.vim)
  let l:request_url = "https://" . l:translate_src . "-" . l:translate_dst . ".dict.cc/?s=" . a:word
  let l:result = systemlist("curl \"" . l:request_url . "\"")
  for line in l:result
    let matched = matchlist(line, '^var c\([12]\)Arr = new Array(\(.*\));$')

    if len(matched) > 1
      if matched[1] == 1
        let l:srcs = matched[2]
      elseif matched[1] == 2
        let l:dsts = matched[2]
      endif
    endif
  endfor

  if !exists("l:srcs") || !exists("l:dsts")
		echohl WarningMsg | echo "[translate.vim] No translation found!" | echohl None
    return
  endif

  let l:srcs = split(l:srcs, ",")
  let l:dsts = split(l:dsts, ",")

  let l:translations = ""
  let l:index = 0
  while l:index < len(l:srcs)
    let l:translations = l:translations . l:index . ": " . l:dsts[l:index][1:-2] . " [" . l:srcs[l:index][1:-2] . "]\n"
    let l:index = l:index + 1
  endwhile

  let l:index = input(l:translations . "----\nUse: ")
  exec ":put =\'" . l:dsts[l:index][1:-2] . "\'"
endfunction

command! -nargs=1 -bang Translate :call s:Translate(<bang>0, <f-args>)

" vim:set et sw=2
