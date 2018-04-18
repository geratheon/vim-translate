function! translate#backends#dictcc(word, invert)
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
