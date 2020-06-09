let s:blacklist = [
  \'log',
  \'',
  \'helm',
  \'yaml',
  \'floaterm',
  \]

function! fileblacklist#GetBlacklist()
  return s:blacklist
endfunction
