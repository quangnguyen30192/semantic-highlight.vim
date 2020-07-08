fu! syntaxcheck#run(curline)
  if &filetype == "kotlin" || &filetype == "java"
    return s:kotlin(a:curline)
  else
    return 0
  endif
endfu

let g:ignoreSyntaxRunAfterKeywords = ["import", "package", "fun ", "class", "interface"]
function! s:kotlin(curline)
  let first_word = matchstr(a:curline, '\<[\$@]*[a-zA-Z\_][a-zA-Z0-9\_]*\>', 0)
  if index(g:ignoreSyntaxRunAfterKeywords, l:first_word) >= 0
    return 1
  endif

  return 0
endfunction
