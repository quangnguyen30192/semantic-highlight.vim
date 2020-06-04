let s:blacklist = [
  \'log',
  \'',
  \'helm',
  \'yaml',
  \]

function! fileblacklist#GetBlacklist()
  return s:blacklist
endfunction
