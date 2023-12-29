" Yank to system clipboard
set clipboard=unnamed
set tabstop=4

unmap <Space>
" commenting out the visual line navigation out as it fails navigating notes with embeds
"" Have j and k navigate visual lines rather than logical ones, normal mode
noremap j gj
noremap k gk
vnoremap j gj
vnoremap k gk

noremap n nzz
noremap N Nzz
noremap <C-d> <C-d>zz 
noremap <C-u> <C-u>zz 



exmap moveLineUp obcommand editor:swap-line-up
exmap moveLineDown obcommand editor:swap-line-down
map <M-K> :moveLineUp
map <M-J> :moveLineDown

" Emulate Original Folding command https://vimhelp.org/fold.txt.html#fold-commands
exmap unfoldall obcommand editor:unfold-all
exmap togglefold obcommand editor:toggle-fold
exmap foldall obcommand editor:fold-all
exmap foldless obcommand editor:fold-less
exmap foldmore obcommand editor:fold-more
nmap zo :togglefold
nmap zc :togglefold
nmap za :togglefold
nmap zm :foldmore
nmap zM :foldall
nmap zr :foldless
nmap zR :unfoldall

" spell check
exmap contextMenu obcommand editor:context-menu
nmap z= :contextMenu
vmap z= :contextMenu


exmap focusRight obcommand editor:focus-right
exmap focusLeft obcommand editor:focus-left
exmap focusTop obcommand editor:focus-top
exmap focusBottom obcommand editor:focus-bottom
exmap vsplit obcommand workspace:split-vertical
exmap split obcommand workspace:split-horizontal
nmap <C-\> :vsplit
nmap <C--> :split
nmap <C-l> :focusRight
nmap <C-h> :focusLeft
nmap <TAB> :focusTop
nmap <s-TAB> :focusBottom


exmap q obcommand workspace:close
nmap <C-q> :q 

exmap goToAction obcommand command-palette:open
nmap ga :goToAction 
vmap ga :goToAction 

exmap goToLink obcommand command-palette:open
nmap gi :goToLink 
vmap gi :goToLink 

exmap goToFile obcommand omnisearch:show-modal
nmap <Space>ff :goToFile 

exmap bo obcommand backlink:toggle-backlinks-in-document
nmap <Space>ub :bo

exmap goToBacklink obcommand obsidian-another-quick-switcher:backlink
nmap <Space>fb :goToBacklink


exmap back obcommand app:go-back
exmap forward obcommand app:go-forward
nmap <C-o> :back
nmap <C-i> :forward

exmap newFile obcommand file-explorer:new-file
exmap delFile obcommand app:delete-file
nmap <C-e> :newFile
nmap md :delFile

exmap toggleLeftSidebar obcommand app:toggle-left-sidebar
exmap toggleRightSidebar obcommand app:toggle-right-sidebar
nmap mh :toggleLeftSidebar
nmap ml :toggleRightSidebar


exmap surround_wiki surround [[ ]]
exmap surround_double_quotes surround " "
exmap surround_single_quotes surround ' '
exmap surround_backticks surround ` `
exmap surround_brackets surround ( )
exmap surround_square_brackets surround [ ]
exmap surround_curly_brackets surround { }
exmap surround_highlight surround == ==
exmap surround_bold surround ** **
exmap surround_italics surround _ _
exmap surround_strikethrough surround ~~ ~~
exmap insertCode obcommand editor:insert-codeblock
exmap header1 obcommand editor:set-heading-1
exmap header2 obcommand editor:set-heading-2
exmap header3 obcommand editor:set-heading-3
exmap header4 obcommand editor:set-heading-4
map [[ :surround_wiki
nunmap s
vunmap s
map s" :surround_double_quotes
map s' :surround_single_quotes
map sc :surround_backticks
map sC :insertCode
map s( :surround_brackets
map s) :surround_brackets
map s[ :surround_square_brackets
map s[ :surround_square_brackets
map s{ :surround_curly_brackets
map s} :surround_curly_brackets
map sb :surround_bold
map si :surround_italics
" map sh :surround_highlight
map sh1 :header1
map sh2 :header2
map sh3 :header3
map sh4 :header4


exmap bulletList obcommand editor:toggle-bullet-list
nmap <Space>b :bulletList


