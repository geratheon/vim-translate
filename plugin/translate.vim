" translate.vim - Quickly translate a word
" Maintainer:   Jonas Kuball <jkuball@tzi.de>
" Version:      0.3

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

function! s:BackendDictCC(word, invert)
  " Set srclang and dstlang as needed
  let srclang = a:invert ? g:translate_dst : g:translate_src
  let dstlang = a:invert ? g:translate_src : g:translate_dst

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

  " When no translation is given, stop
  if !has_key(strtranslations, 1) || !has_key(strtranslations, 2)
    throw "No translation found."
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
  " TODO: Remove elements where both or one translation(s) are an empty string
  let srcs = map(split(dicttranslations[srclang], ",")[1:-1], 'v:val[1:-2]')
  let dsts = map(split(dicttranslations[dstlang], ",")[1:-1], 'v:val[1:-2]')
  if len(srcs) !=# len(dsts)
    " This is a classic 'this should never happen' type of thing.
    throw "Bad things happening!"
  endif

  let translations = []
  let index = 0
  while index < len(srcs)
    " Build a readable translation string
    call add(translations, [srcs[index], dsts[index]])
    let index = index + 1
  endwhile
  return translations
endfunction
let g:translate_backends["dict.cc"] = function("s:BackendDictCC")

function! s:Translate(word, invert)
  " Get the translation with the current backend
  let result = ""
  try
    let result = g:translate_backends[g:translate_backend](a:word, a:invert)
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
    let @" = result[index - 1][1]
    put ""
  catch
    echohl WarningMsg | echo "\nNothing inserted." | echohl None
  endtry
endfunction

command! -nargs=1 -bang Translate :call s:Translate(<f-args>, <bang>0)

" vim:set et sw=2
