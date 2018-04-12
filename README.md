# translate.vim

Sometimes I just don't know the german word for an english one that's in my mind right now, like *"translation"*. In that case, I can just type `:Tr translation` to look it up directly in vim. The plugin then fetches a list of possible translations and lets me choose one to insert it directly.

## Features

* `:Tr[anslate][!] {word}`: Searches online for `{word}` and gives you a list to choose from. If `[!]` is given, it reverses the source and target language.

For more detailled information, see `:help :Translate`.

## Configuration

The default languages for this plugin are set to **English** and **German**, since I always now the english word but never the german one. If you want to set your own, you can set them in your `.vimrc`.

```vimscript
let g:translate_src = "en"
let g:translate_dst = "de"
```

The translation website of my choice is [dict.cc](https://www.dict.cc/). Theoretically spoken, this plugin can support every dictionary in the world, but right now, only one backend is implemented. You can, however, write your own. See `:help translate-backends`.

## Dependencies

The only dependency is to have [cURL](http://curl.haxx.se) installed and be located in your `$PATH`.

## License

Copyright © Jonas Kuball.  Distributed under the same terms as Vim itself.
See `:help license`.
