" vim/syntax に保存
"
"au BufRead,BufNewFile orgmap.* set filetype=orgmap
"
syntax match orgmapWall       /[-|]/
syntax match orgmapWall2      /X/
syntax match orgmapEncount    /@/
syntax match orgmapEncountDark /&/
syntax match orgmapDoor       /+/
syntax match orgmapUnlockDoor /=/
syntax match orgmapSecretDoor /*/
syntax match orgmapPit        /\^/
syntax match orgmapPitE       /\~/
syntax match orgmapEvent      /[a-z]/
syntax match orgmapEvent      /[ABCDEFGHIJKLMNOPQRSTUVWYZ]/
syntax match orgmapDarkzone   /\$/
syntax match orgmapDarkzoneE  /&/
syntax match orgmapStairs     /[<>]/

highlight orgmapWall        gui=reverse guifg=#268bd2
highlight orgmapWall2       gui=reverse guifg=#b58900 guibg=#3c4194
highlight orgmapEncount     gui=reverse guifg=#3c4194
highlight orgmapEncountDark gui=reverse guifg=#3c4194 guibg=blue
highlight orgmapDoor        gui=bold guifg=#b58900
highlight orgmapUnlockDoor  gui=bold guifg=#b58900 
highlight orgmapSecretDoor  gui=bold,reverse guifg=lightgreen guibg=#b58900
highlight orgmapPit         gui=bold,underline guifg=green
highlight orgmapPitE        gui=bold,underline guifg=green guibg=#3c4194
highlight orgmapEvent       gui=bold guifg=darkyellow
highlight orgmapEventE      guifg=#b58900 guibg=#3c4194
highlight orgmapDarkzone    gui=reverse guifg=#586e75 guibg=blue
highlight orgmapDarkzoneE   gui=reverse guifg=#3c4194 guibg=blue
highlight orgmapStairs      gui=bold guifg=red

let b:current_syntax = "orgmap"

