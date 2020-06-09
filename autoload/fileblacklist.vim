let s:blacklist = [
  \'log',
  \'',
  \'helm',
  \'yaml',
  \'floaterm',
  \'vim',
  \]

function! fileblacklist#GetBlacklist()
  return s:blacklist
endfunction
