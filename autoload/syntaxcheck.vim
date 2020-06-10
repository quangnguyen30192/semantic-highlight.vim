fu! syntaxcheck#run(curline)
  if &filetype == "kotlin" || &filetype == "java"
    return s:kotlin(a:curline)
  else
    return 0
  endif
endfu

fu! s:kotlin(curline)
  let first_word = matchstr(a:curline, '\<[\$@]*[a-zA-Z\_][a-zA-Z0-9\_]*\>', 0) 
  if (first_word == "import" || first_word == "package")
    return 1
  else
    return 0
  endif
endfu
