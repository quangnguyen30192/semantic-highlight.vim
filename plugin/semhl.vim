" A special thanks goes out to John Leimon <jleimon@gmail.com>
" for his more complete C/C++ version,
" which served as a great basis for understanding
" regex matching in Vim

" Allow users to configure the plugin to auto start for certain filetypes
if (exists('g:semanticEnableFileTypes'))
	if type(g:semanticEnableFileTypes) == type([])
		execute 'autocmd FileType ' . join(g:semanticEnableFileTypes, ',') . ' call s:enableHighlight()'
	elseif type(g:semanticEnableFileTypes) == type({})
		execute 'autocmd FileType ' . join(keys(g:semanticEnableFileTypes), ',') . ' call s:enableHighlight()'
		execute 'autocmd CursorHold ' . join(map(values(g:semanticEnableFileTypes), '"*." . v:val'), ',') . ' call s:semHighlight()'
	endif
endif

" Set defaults for colors
let s:semanticGUIColors = ['#bd93f9', '#ff5555', '#6272a4', '#8be9fd', '#50fa7b', '#ffb86c', '#ff79c6', '#f1fa8c', '#91C9C4', '#C2DD8E', '#F7C871', '#91D4EF', '#E3747A', '#E98C6E','#E65A65', '#F44336', '#EF5350', '#EC407A', '#E91E63', '#AB47BC', '#7E57C2', '#5C6BC0', '#3F51B5', '#64B5F6', '#4FC3F7', '#29B6F6', '#4DD0E1', '#26C6DA', '#81C784', "#FA6BB2", "#47F2D4", "#F47F86", "#2ED8FF", "#D386F1", "#97DFD6", "#EF874A", "#48EDF0", "#C0AE50", "#D7D1EB", "#57F0AC", "#8BE289", "#D38AC6", "#C8EE63", "#ED9C36", "#9DEA74", "#40B7E5", "#EEA3C2", "#7CE9B6", "#8CEC58", "#D8A66C", "#51C03B", "#C4CE64", "#45E648", "#63A5F3", "#EA8C66", "#D2D43E",  "#E4B7CB", "#B092F4", "#44C58C", "#D1E998", "#76E4F2", "#E19392", "#BF9FD6", "#E8C25B", "#58F596", "#6BAEAC","#7EF1DB", "#E8D65C", "#D38AE0", "#5CD8B8", "#B6BF6B", "#BEE1F1", "#EBE77B", "#84A5CD", "#CFEF7A", "#E4BB34", "#ECB151", "#BDC9F2", "#5EB0E9", "#E09764", "#9BE3C8", "#C8CD4F", '#e4e4e4', '#fdf6e3',  '#cb4b16', '#d33682', '#5f5faf','#268bd2', '#00afaf']
let s:semanticTermColors = range(20)

" The user can change the GUI/Term colors, but cannot directly access the list of colors we use
" If the user overrode the default in their vimrc, use that
let g:semanticGUIColors = exists('g:semanticGUIColors') ? g:semanticGUIColors : s:semanticGUIColors
let g:semanticTermColors = exists('g:semanticTermColors') ? g:semanticTermColors : s:semanticTermColors

" Allow the user to turn cache off
let g:semanticUseCache = exists('g:semanticUseCache') ? g:semanticUseCache : 1
let g:semanticPersistCache = exists('g:semanticPersistCache') ? g:semanticPersistCache : 1
let g:semanticPersistCacheLocation = exists('g:semanticPersistCacheLocation') ? g:semanticPersistCacheLocation : $HOME . '/.semantic-highlight-cache'

" Allow the user to override blacklists
let g:semanticEnableBlacklist = exists('g:semanticEnableBlacklist') ? g:semanticEnableBlacklist : 1

let s:blacklist = {}
if g:semanticEnableBlacklist
	let s:blacklist = blacklist#GetBlacklist()
endif

let s:containedinlist = containedinlist#GetContainedinlist()

let g:semanticUseBackground = 0
let s:hasBuiltColors = 0

command! SemanticHighlight call s:semHighlight()
command! SemanticHighlightRevert call s:disableHighlight()
command! SemanticHighlightToggle call s:toggleHighlight()
command! RebuildSemanticColors call s:buildColors()

function! s:readCache() abort
	if !filereadable(g:semanticPersistCacheLocation)
		return []
	endif

	let l:localCache = {}
	let s:cacheList = readfile(g:semanticPersistCacheLocation)
	for s:cacheListItem in s:cacheList
		let s:cacheListItemList = eval(s:cacheListItem)
		let l:localCache[s:cacheListItemList[0]] = s:cacheListItemList[1]
	endfor

	if exists("s:cacheListItem")
		unlet s:cacheListItem s:cacheList
	endif

	return l:localCache
endfunction

let s:cache = {}
let b:cache_defined = {}
if g:semanticPersistCache && filereadable(g:semanticPersistCacheLocation)
	let s:cache = s:readCache()
endif

autocmd VimLeave * call s:persistCache()

function! s:persistCache()
	let l:cacheList = []
	let l:mergedCache = extend(s:readCache(), s:cache)
	for [match,color] in items(l:mergedCache)
		call add(l:cacheList, string([match, color]))
		unlet match color
	endfor
	call writefile(l:cacheList, g:semanticPersistCacheLocation)
endfunction

function! s:getCachedColor(current_color, match)
	if !g:semanticUseCache
		return a:current_color
	endif

	if (has_key(s:cache, a:match))
		return s:cache[a:match]
	endif

	let s:cache[a:match] = a:current_color
	return a:current_color
endfunction

function! s:semHighlight()
	if s:hasBuiltColors == 0
		call s:buildColors()
	endif

	let b:cache_defined = {}

	let buflen = line('$')
	let pattern = '\<[\$@]*[a-zA-Z\_][a-zA-Z0-9\_]*\>'
	let colorLen = len(s:semanticColors)
	let cur_color = str2nr(matchstr(reltimestr(reltime()), '\v\.@<=\d+')[1:]) % colorLen    " found on https://stackoverflow.com/questions/12737977/native-vim-random-number-script

	while buflen
		let curline = getline(buflen)
		let index = 0
		while 1
			let match = matchstr(curline, pattern, index)

			if (empty(match))
				break
			endif

			let l:no_blacklist_exists_for_filetype = empty(s:blacklist) || !has_key(s:blacklist, &filetype)
			if ((l:no_blacklist_exists_for_filetype || index(s:blacklist[&filetype], match) == -1) && !has_key(b:cache_defined, match))
				let b:cache_defined[match] = 1
				let l:containedin = ''
				if (!empty(s:containedinlist) && has_key(s:containedinlist, &filetype))
					let l:containedin = ' containedin=' . s:containedinlist[&filetype]
				endif

				execute 'syn keyword _semantic' . s:getCachedColor(cur_color, match) . l:containedin . ' ' . match
				let cur_color = (cur_color + 1) % colorLen
			endif

			let index += len(match) + 1
		endwhile
		let buflen -= 1
	endwhile
endfunction

function! s:buildColors()
	if (g:semanticUseBackground)
		let type = 'bg'
	else
		let type = 'fg'
	endif
	if $NVIM_TUI_ENABLE_TRUE_COLOR || has('gui_running') || (exists('&guicolors') && &guicolors) || (exists('&termguicolors') && &termguicolors)
		let colorType = 'gui'
		" Update color list in case the user made any changes
		let s:semanticColors = g:semanticGUIColors
	else
		let colorType = 'cterm'
		" Update color list in case the user made any changes
		let s:semanticColors = g:semanticTermColors
	endif

	let semIndex = 0
	for semCol in s:semanticColors
		execute 'hi! def _semantic'.semIndex.' ' . colorType . type . '='.semCol
		let semIndex += 1
	endfor
	let s:hasBuiltColors = 1
endfunction

function! s:disableHighlight()
	let b:semanticOn = 0
	for key in range(len(s:semanticColors))
		execute 'syn clear _semantic'.key
	endfor

	let b:cache_defined = {}
endfunction

function! s:enableHighlight()
	let b:cache_defined = {}
	call s:semHighlight()
	let b:semanticOn = 1
endfunction

function! s:toggleHighlight()
	if (exists('b:semanticOn') && b:semanticOn == 1)
		call s:disableHighlight()
    let s:isHighlightBuffer = 0
	else
		call s:semHighlight()
		let b:semanticOn = 1
    let s:isHighlightBuffer = 1
	endif
endfunction

let s:isHighlightBuffer = -1

function! s:autoHighlightBuffer()
  if s:isHighlightBuffer == -1
    return 
  endif

  if s:isHighlightBuffer
    call s:enableHighlight()
  else
    call s:disableHighlight()
  endif
endfunction

autocmd BufEnter * call s:autoHighlightBuffer()
