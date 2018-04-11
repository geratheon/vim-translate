" translate.vim - Quickly translate a word
" Maintainer:   Jonas Kuball <jkuball@tzi.de>
" Version:      0.2

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
  " Set srclang and dstlang as needed
  let srclang = g:translate_src
  let dstlang = g:translate_dst
  if a:invert
    let srclang = g:translate_dst
    let dstlang = g:translate_src
  endif

  " Make a server request and extract the lines containing the translations
  " TODO: urlencode a:word for special cases like umlauts (see tpopes unimpaired.vim)
  let strtranslations = {}
  let request_url = "https://" . srclang . dstlang . ".dict.cc/?s=" . a:word
  let result = systemlist("curl \"" . request_url . "\"")
  for line in result
    let matched = matchlist(line, '^var c\([12]\)Arr = new Array(\(.*\));$')
    if len(matched) > 1
      let strtranslations[matched[1]] = matched[2]
    endif
  endfor

  " When no translation is given, return
  if !has_key(strtranslations, 1) || !has_key(strtranslations, 2)
		echohl WarningMsg | echo "No translation found." | echohl None
    return
  endif

  " As bad as this sounds, it seems like strtranslations[1] and
  " strtranslations[2] are the same language whatever direction you're
  " translation and they're sorted inversely to the alphabetical order
  " of the language names. Yeah. So, I have to determine what is the
  " srclang and what is dstlang.
  let dicttranslations = {}
  let langs = sort([srclang, dstlang])
  let dicttranslations[langs[0]] = strtranslations[2]
  let dicttranslations[langs[1]] = strtranslations[1]

  " Now make pairs of translations by splitting the lists (and removing
  " the first element hardcoded). Also, remove the double quotes around
  " the words for better usage.
  " TODO: Remove elements where both translations are an empty string
  let srcs = map(split(dicttranslations[srclang], ",")[1:-1], 'v:val[1:-2]')
  let dsts = map(split(dicttranslations[dstlang], ",")[1:-1], 'v:val[1:-2]')
  if len(srcs) !=# len(dsts)
    " This is a classic 'this should never happen' type of thing.
		echohl WarningMsg | echo "Bad things happening!" | echohl None
    return
  endif
  let translations = []
  let index = 0
  while index < len(srcs)
    " Build a readable translation string
    call add(translations, (index + 1) . ":" . srcs[index] . " [" . dsts[index]. "]")
    let index = index + 1
  endwhile

  " Let the user decide which translation he wants to use
  call insert(translations, "Select one:", 0)
  let index = inputlist(translations)
  try
    if index ==# "Select one:"
      throw 1
    endif
    " Put the translation below the cursor
    exec ":put =\'" . dsts[index] . "\'"
  catch
    echohl WarningMsg | echo "\nNothing inserted." | echohl None
  endtry
endfunction

command! -nargs=1 -bang Translate :call s:Translate(<bang>0, <f-args>)

" vim:set et sw=2
