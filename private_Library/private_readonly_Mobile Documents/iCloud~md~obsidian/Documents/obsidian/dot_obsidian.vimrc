""" """ """ """ """ """ Native Vim Emulation "" """ """ """ """ """ """ """ """ """ """ """ """ """
set clipboard=unnamed
set tabstop=4

unmap <Space>

"" Have j and k navigate visual lines rather than logical ones, normal mode
noremap j gj
noremap k gk
vnoremap j gj
vnoremap k gk

noremap n nzz
noremap N Nzz
noremap <C-d> <C-d>zz 
noremap <C-u> <C-u>zz 

exmap back obcommand app:go-back
exmap forward obcommand app:go-forward
nmap <C-o> :back
nmap <C-i> :forward

map <M-k> :moveLineUp
map <M-j> :moveLineDown

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


exmap focusRight obcommand editor:focus-right
exmap focusLeft obcommand editor:focus-left
exmap focusTop obcommand editor:focus-top
exmap focusBottom obcommand editor:focus-bottom
exmap vsplit obcommand workspace:split-vertical
exmap split obcommand workspace:split-horizontal
nmap <Space>| :vsplit
nmap <Space>- :split
nmap <C-l> :focusRight
nmap <C-h> :focusLeft
nmap <C-k> :focusTop
nmap <C-j> :focusBottom

""" """ """ """ """ Workspace""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """

exmap toggleBacklinks obcommand backlink:toggle-backlinks-in-document
exmap toggleLeftSidebar obcommand app:toggle-left-sidebar
exmap toggleRightSidebar obcommand app:toggle-right-sidebar

nmap <Space>tb :toggleBacklinks
nmap <Space>tl :toggleLeftSidebar
nmap <Space>tr :toggleRightSidebar

""" """ """ """ """ Command Palette""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """

exmap commandsOpen obcommand command-palette:open
exmap contextMenu obcommand editor:context-menu
nmap <Space>co :commandsOpen 
vmap <Space>co :commandsOpen 
nmap <Space>cm :contextMenu
vmap <Space>cm :contextMenu

""" """ """ """ """ File Management""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """

exmap fileQuit obcommand workspace:close
exmap goToFile obcommand omnisearch:show-modal
exmap fileBacklinks obcommand obsidian-another-quick-switcher:backlink
exmap fileNew obcommand file-explorer:new-file
exmap fileDelete obcommand app:delete-file
exmap openLinkInLeaf obcommand editor:open-link-in-new-leaf
exmap openLinkInSplit obcommand editor:open-link-in-new-split
exmap openLinkInWindow obcommand editor:open-link-in-new-window

nmap <Space>fn :fileNew
nmap <Space>fd :fileDelete
nmap <Space>fq :fileQuit
nmap <Space>fb :fileBacklinks
nmap <Space>ff :goToFile 
nmap <Space>fl :openLinkInLeaf
nmap <Space>fs :openLinkInSplit
nmap <Space>fw :openLinkInWindow

""" """ """ """ """ Editing""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """

exmap moveLineUp obcommand editor:swap-line-up
exmap moveLineDown obcommand editor:swap-line-down
exmap surroundLink surround [[ ]]
exmap quoteDouble surround " "
exmap quoteSingle surround ' '
exmap surroundCode surround ` `
exmap brackets surround ( )
exmap bracketsSquare surround [ ]
exmap bracketsCurly surround { }
exmap surroundCodeBlock obcommand editor:insert-codeblock
nunmap s
vunmap s
map sl  :surroundLink
map sqd :quoteDouble
map sqs :quoteSingle
map scc :surroundCode
map scb :surroundCodeBlock
map sbb :brackets
map sbs :bracketsSquare
map sbc :bracketsCurly

exmap surround_highlight surround == ==
exmap surround_bold surround ** **
exmap surround_italics surround _ _
exmap surround_strikethrough surround ~~ ~~
map ssb :surround_bold
map ssi :surround_italics
map sss :surround_strikethrough
map ssh :surround_highlight

exmap header1 obcommand editor:set-heading-1
exmap header2 obcommand editor:set-heading-2
exmap header3 obcommand editor:set-heading-3
exmap header4 obcommand editor:set-heading-4
exmap header5 obcommand editor:set-heading-5
exmap header6 obcommand editor:set-heading-6
exmap header7 obcommand editor:set-heading-7
map <Space>ha :header1
map <Space>hb :header2
map <Space>hc :header3
map <Space>hd :header4
map <Space>he :header5
map <Space>hf :header6
map <Space>hg :header7

exmap listBullet obcommand editor:toggle-bullet-list
exmap listNumber obcommand editor:toggle-numbered-list
exmap listChecklist obcommand editor:toggle-checklist-status
vmap <Space>lb :listBullet
nmap <Space>lb :listBullet
vmap <Space>ln :listNumber
nmap <Space>ln :listNumber
vmap <Space>lc :listChecklist
nmap <Space>lc :listChecklist

""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """
""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """
""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """
""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """

""" """ """ """ """ Available commands "" """ """ """ """ """ """ """ """ """ """ """ """ """
" editor:save-file
" app:delete-file
" app:go-back
" app:go-forward
" app:open-help
" app:open-sandbox-vault
" app:open-settings
" app:open-vault
" app:reload
" app:show-debug-info
" app:show-release-notes
" app:toggle-default-new-pane-mode
" app:toggle-left-sidebar
" app:toggle-right-sidebar
" backlink:open
" backlink:open-backlinks
" backlink:toggle-backlinks-in-document
" bookmarks:bookmark-all-tabs
" bookmarks:bookmark-current-heading
" bookmarks:bookmark-current-search
" bookmarks:bookmark-current-section
" bookmarks:bookmark-current-view
" bookmarks:open
" bookmarks:unbookmark-current-view
" canvas:convert-to-file
" canvas:export-as-image
" canvas:jump-to-group
" canvas:new-file
" command-palette:open
" copilot:add-custom-prompt
" copilot:apply-adhoc-prompt
" copilot:apply-custom-prompt
" copilot:change-tone-prompt
" copilot:chat-toggle-window
" copilot:chat-toggle-window-note-area
" copilot:clear-local-vector-store
" copilot:count-tokens
" copilot:count-total-vault-tokens
" copilot:delete-custom-prompt
" copilot:edit-custom-prompt
" copilot:eli5-prompt
" copilot:emojify-prompt
" copilot:fix-grammar-prompt
" copilot:force-reindex-vault-to-vector-store
" copilot:garbage-collect-vector-store
" copilot:generate-glossary-prompt
" copilot:generate-toc-prompt
" copilot:index-vault-to-vector-store
" copilot:make-longer-prompt
" copilot:make-shorter-prompt
" copilot:press-release-prompt
" copilot:remove-urls-prompt
" copilot:rewrite-tweet-prompt
" copilot:rewrite-tweet-thread-prompt
" copilot:set-chat-note-context
" copilot:set-vault-qa-exclusion
" copilot:simplify-prompt
" copilot:summarize-prompt
" copilot:translate-selection-prompt
" daily-notes
" daily-notes:goto-next
" daily-notes:goto-prev
" dataview:dataview-drop-cache
" dataview:dataview-force-refresh-views
" dataview:dataview-rebuild-current-view
" editor:add-cursor-above
" editor:add-cursor-below
" editor:attach-file
" editor:clear-formatting
" editor:context-menu
" editor:cycle-list-checklist
" editor:delete-paragraph
" editor:focus
" editor:focus-bottom
" editor:focus-left
" editor:focus-right
" editor:focus-top
" editor:fold-all
" editor:fold-less
" editor:fold-more
" editor:follow-link
" editor:insert-callout
" editor:insert-codeblock
" editor:insert-embed
" editor:insert-horizontal-rule
" editor:insert-link
" editor:insert-mathblock
" editor:insert-table
" editor:insert-tag
" editor:insert-wikilink
" editor:open-link-in-new-leaf
" editor:open-link-in-new-split
" editor:open-link-in-new-window
" editor:open-search
" editor:open-search-replace
" editor:rename-heading
" editor:set-heading
" editor:set-heading-0
" editor:set-heading-1
" editor:set-heading-2
" editor:set-heading-3
" editor:set-heading-4
" editor:set-heading-5
" editor:set-heading-6
" editor:swap-line-down
" editor:swap-line-up
" editor:table-col-after
" editor:table-col-align-center
" editor:table-col-align-left
" editor:table-col-align-right
" editor:table-col-before
" editor:table-col-copy
" editor:table-col-delete
" editor:table-col-left
" editor:table-col-right
" editor:table-row-after
" editor:table-row-before
" editor:table-row-copy
" editor:table-row-delete
" editor:table-row-down
" editor:table-row-up
" editor:toggle-blockquote
" editor:toggle-bold
" editor:toggle-bullet-list
" editor:toggle-checklist-status
" editor:toggle-code
" editor:toggle-comments
" editor:toggle-fold
" editor:toggle-fold-properties
" editor:toggle-highlight
" editor:toggle-inline-math
" editor:toggle-italics
" editor:toggle-numbered-list
" editor:toggle-source
" editor:toggle-spellcheck
" editor:toggle-strikethrough
" editor:unfold-all
" file-explorer:duplicate-file
" file-explorer:move-file
" file-explorer:new-file
" file-explorer:new-file-in-current-tab
" file-explorer:new-file-in-new-pane
" file-explorer:open
" file-explorer:reveal-active-file
" file-recovery:open
" global-search:open
" graph:animate
" graph:open
" graph:open-local
" insert-current-date
" insert-current-time
" insert-template
" markdown-importer:open
" markdown:add-metadata-property
" markdown:clear-metadata-properties
" markdown:edit-metadata-property
" markdown:toggle-preview
" metadata-extractor:write-allExceptMd-json
" metadata-extractor:write-canvas-json
" metadata-extractor:write-metadata-json
" metadata-extractor:write-tags-json
" note-composer:extract-heading
" note-composer:merge-file
" note-composer:split-file
" obsidian-advanced-uri:copy-uri-block
" obsidian-advanced-uri:copy-uri-command
" obsidian-advanced-uri:copy-uri-current-file
" obsidian-advanced-uri:copy-uri-current-file-simple
" obsidian-advanced-uri:copy-uri-daily
" obsidian-advanced-uri:copy-uri-search-and-replace
" obsidian-another-quick-switcher:backlink
" obsidian-another-quick-switcher:grep
" obsidian-another-quick-switcher:header-floating-search-in-file
" obsidian-another-quick-switcher:header-search-in-file
" obsidian-another-quick-switcher:in-file-search
" obsidian-another-quick-switcher:link
" obsidian-another-quick-switcher:move
" obsidian-another-quick-switcher:search-command_2-hop-link-search
" obsidian-another-quick-switcher:search-command_file-name-fuzzy-search
" obsidian-another-quick-switcher:search-command_file-name-search
" obsidian-another-quick-switcher:search-command_landmark-search
" obsidian-another-quick-switcher:search-command_link-search
" obsidian-another-quick-switcher:search-command_recent-search
" obsidian-another-quick-switcher:search-command_star-search
" obsidian-book-search-plugin:open-book-search-modal
" obsidian-book-search-plugin:open-book-search-modal-to-insert
" obsidian-excalidraw-plugin:convert-excalidraw
" obsidian-excalidraw-plugin:convert-text2MD
" obsidian-excalidraw-plugin:convert-to-excalidraw
" obsidian-excalidraw-plugin:crop-image
" obsidian-excalidraw-plugin:delete-file
" obsidian-excalidraw-plugin:disable-binding
" obsidian-excalidraw-plugin:disable-frameclipping
" obsidian-excalidraw-plugin:disable-framerendering
" obsidian-excalidraw-plugin:excalidraw-autocreate
" obsidian-excalidraw-plugin:excalidraw-autocreate-and-embed
" obsidian-excalidraw-plugin:excalidraw-autocreate-and-embed-new-tab
" obsidian-excalidraw-plugin:excalidraw-autocreate-and-embed-on-current
" obsidian-excalidraw-plugin:excalidraw-autocreate-and-embed-popout
" obsidian-excalidraw-plugin:excalidraw-autocreate-newtab
" obsidian-excalidraw-plugin:excalidraw-autocreate-on-current
" obsidian-excalidraw-plugin:excalidraw-autocreate-popout
" obsidian-excalidraw-plugin:excalidraw-convert-image-from-url-to-local-file
" obsidian-excalidraw-plugin:excalidraw-disable-autosave
" obsidian-excalidraw-plugin:excalidraw-download-lib
" obsidian-excalidraw-plugin:excalidraw-embeddable-poroperties
" obsidian-excalidraw-plugin:excalidraw-embeddables-relative-scale
" obsidian-excalidraw-plugin:excalidraw-enable-autosave
" obsidian-excalidraw-plugin:excalidraw-insert-last-active-transclusion
" obsidian-excalidraw-plugin:excalidraw-insert-transclusion
" obsidian-excalidraw-plugin:excalidraw-open
" obsidian-excalidraw-plugin:excalidraw-open-on-current
" obsidian-excalidraw-plugin:excalidraw-publish-svg-check
" obsidian-excalidraw-plugin:excalidraw-unzip-file
" obsidian-excalidraw-plugin:export-image
" obsidian-excalidraw-plugin:fullscreen
" obsidian-excalidraw-plugin:import-svg
" obsidian-excalidraw-plugin:insert-LaTeX-symbol
" obsidian-excalidraw-plugin:insert-active-pdfpage
" obsidian-excalidraw-plugin:insert-command
" obsidian-excalidraw-plugin:insert-image
" obsidian-excalidraw-plugin:insert-link
" obsidian-excalidraw-plugin:insert-link-to-element
" obsidian-excalidraw-plugin:insert-link-to-element-area
" obsidian-excalidraw-plugin:insert-link-to-element-frame
" obsidian-excalidraw-plugin:insert-link-to-element-group
" obsidian-excalidraw-plugin:insert-md
" obsidian-excalidraw-plugin:insert-pdf
" obsidian-excalidraw-plugin:open-image-excalidraw-source
" obsidian-excalidraw-plugin:release-notes
" obsidian-excalidraw-plugin:reset-image-to-100
" obsidian-excalidraw-plugin:run-ocr
" obsidian-excalidraw-plugin:save
" obsidian-excalidraw-plugin:scriptengine-store
" obsidian-excalidraw-plugin:search-text
" obsidian-excalidraw-plugin:toggle-excalidraw-view
" obsidian-excalidraw-plugin:toggle-lefthanded-mode
" obsidian-excalidraw-plugin:toggle-lock
" obsidian-excalidraw-plugin:tray-mode
" obsidian-excalidraw-plugin:universal-add-file
" obsidian-hider:toggle-app-ribbon
" obsidian-hider:toggle-hider-status
" obsidian-hider:toggle-tab-containers
" obsidian-jira-issue:obsidian-jira-count-template-fence
" obsidian-jira-issue:obsidian-jira-issue-clear-cache
" obsidian-jira-issue:obsidian-jira-issue-template-fence
" obsidian-jira-issue:obsidian-jira-search-wizard-fence
" obsidian-mind-map:app:markmap-preview
" obsidian-plugin-prettier:format-note
" obsidian-plugin-prettier:format-selection
" obsidian-spaced-repetition:srs-cram-flashcards
" obsidian-spaced-repetition:srs-cram-flashcards-in-note
" obsidian-spaced-repetition:srs-note-review-easy
" obsidian-spaced-repetition:srs-note-review-good
" obsidian-spaced-repetition:srs-note-review-hard
" obsidian-spaced-repetition:srs-note-review-open-note
" obsidian-spaced-repetition:srs-review-flashcards
" obsidian-spaced-repetition:srs-review-flashcards-in-note
" obsidian-spaced-repetition:srs-view-stats
" omnisearch:show-modal
" omnisearch:show-modal-infile
" open-with-default-app:open
" open-with-default-app:show
" outgoing-links:open
" outgoing-links:open-for-current
" outline:open
" outline:open-for-current
" properties:open
" properties:open-local
" random-note
" slides:start
" switcher:open
" tag-pane:open
" text-extractor:extract-to-clipboard
" text-extractor:extract-to-new-note
" theme-picker:open-theme-picker
" theme:switch
" theme:use-dark
" theme:use-light
" todoist-sync-plugin:todoist-add-task
" todoist-sync-plugin:todoist-add-task-current-page
" todoist-sync-plugin:todoist-sync
" window:reset-zoom
" window:toggle-always-on-top
" window:zoom-in
" window:zoom-out
" workspace:close
" workspace:close-others
" workspace:close-others-tab-group
" workspace:close-tab-group
" workspace:close-window
" workspace:copy-path
" workspace:copy-url
" workspace:edit-file-title
" workspace:export-pdf
" workspace:goto-last-tab
" workspace:goto-tab-1
" workspace:goto-tab-2
" workspace:goto-tab-3
" workspace:goto-tab-4
" workspace:goto-tab-5
" workspace:goto-tab-6
" workspace:goto-tab-7
" workspace:goto-tab-8
" workspace:move-to-new-window
" workspace:new-tab
" workspace:next-tab
" workspace:open-in-new-window
" workspace:previous-tab
" workspace:show-trash
" workspace:split-horizontal
" workspace:split-vertical
" workspace:toggle-pin
" workspace:toggle-stacked-tabs
" workspace:undo-close-pane
""" """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """ """
