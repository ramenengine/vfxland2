empty only forth definitions
include lib/gl1pre.f
require keys.f
require input.f
require lib/strout.f
require lib/a.f
require scene.f
require script.f
require utils.f
require objlib.f
require tileutils.f

\ 0 value tile#
true value info
0 value scene#
0 value layer#
true value snapping
0 value selected  \ object
0 value hovered   \ object
0 value counter
0 value dragging  \ bool
0 value prefab#

create tile-selection 0 , 0 , 1 , 1 ,  \ col , row , #cols , #rows , 

/screen
    screen-getset scrollx scrollx!
    screen-getset scrolly scrolly!
to /screen

screen maped
screen tiles
screen attributes
screen objed
screen objsel

256 256 plane: tbrush ;plane    \ clipboard tilemap
create tsel /tilemap /allot     \ describes selection source
0 value tsel-plane#             \ index of the background plane where the selection is

: black  0e 0e 0e color 1e alpha ;
: grey   0.5e 0.5e 0.5e color 1e alpha ;
: keycode alevt KEYBOARD_EVENT.keycode @ ;
: bmpwh dup al_get_bitmap_width swap al_get_bitmap_height ;
: lb-pressed ms1 1 al_mouse_button_down 0= ms0 1 al_mouse_button_down 0<> and ;
: lb-letgo  ms1 1 al_mouse_button_down 0<> ms0 1 al_mouse_button_down 0= and ;

: the-scene  scene# scene ;
: the-layer  scene# scene [[ layer# s.layer ]] ;
: the-plane  layer# bgp ;
: the-base   the-plane 's tm.base ;
: the-stride the-plane 's tm.stride ;
: the-bmp#   the-plane 's tm.bmp# ;

\        fmouse >v zoom uv/ the-plane 's scrollxy v+ v>
\        >v tm.twh v/ vtrunc v>
\        >v tm.twh v* v>
\        >v scrollxy v- v>

\        fmouse >v zoom uv/ the-plane 's scrollxy v+
\        tm.twh v/ vtrunc tm.twh v* scrollxy v- v>

: maus  mouse zoom f>s / swap zoom f>s / swap scrollx scrolly 2+ ;
: colrow  the-plane [[ fswap tm.tw f/ ftrunc fswap tm.th f/ ftrunc ]] ;
: tilexy  the-plane [[ fswap tm.tw f* fswap tm.th f* ]] ;
: scroll-  fswap scrollx s>f f- fswap scrolly s>f f- ;

: resize-tilemap ( cols rows tilemap )
    [[ 2dup tm.rows! tm.cols!
    the-plane [[ tm.tw tm.th ]] tm.th! tm.tw! 
    s>f tm.th f* tm.h!  s>f tm.tw f* tm.w! ]] ;

: select-tiles ( col row cols rows )
    tsel-plane# bgp tsel /tilemap move
    layer# to tsel-plane#  tsel resize-tilemap
    tsel-plane# bgp [[ ( row ) tm.stride * swap ( col ) cells + tm.base + ]]
        tsel [[ tm.base! ]]
;

: pick-tiles ( tile# cols rows )
    the-bmp# bmp 0= if 3drop exit then
    the-bmp# bmp bmpw the-plane 's tm.tw f>s /
        | tcols #rows #cols t# |
    #cols #rows 2dup tbrush resize-tilemap tsel resize-tilemap
    #cols 0 do #rows 0 do  i j tcols * + t# + i j tbrush find-tile !
    loop loop 
;

: tile#   ( - n ) tbrush 's tm.base @ ;
: tile#!  ( n ) 1 1 tbrush resize-tilemap tbrush 's tm.base !
    1 1 tile-selection 8 + 2! ;
0 tile#!

: copy-tiles
    tsel [[ tm.cols tm.rows ]] tbrush resize-tilemap
    tsel tbrush 0 0 tmove
;
: there  maus 2s>f colrow f>s f>s swap ;
: paste-tiles  tbrush the-plane there tmove ;
: erase-tiles
    there the-plane find-tile
        tsel [[ tm.cols cells tm.rows ]] the-plane 's tm.stride 2erase ;
: cut-tiles   copy-tiles erase-tiles ;
    

    
    

: load  ( scene# )
    to scene#
    
    \ create any tilemap files if they don't already exist.
    the-scene [[
        4 0 do i s.layer [[
            l.zstm @ if l.zstm zcount FileExist? not if
                cr ." Auto-creating " l.zstm count type
                the-scene 's s.w l.tw f/ f>s
                the-scene 's s.h l.th f/ f>s l.zstm create-stm
            then then
        ]] loop
    ]]
    
    scene# load  \ load tilemaps, tile attributes, layer settings, and objects from given scene
    
    \ load tileset(s)
    the-scene [[
        4 0 do i s.layer [[ l.bmp# l.zbmp load-bitmap ]] loop
    ]]
    
    \ copy the layer properties from the scene layer to the engine layer
    the-layer   [[ l.tw l.th l.bmp# ]]
    the-plane   [[ tm.bmp#! tm.th! tm.tw! ]]
    
;

: load-data
    s" data.f" included
    load-prefabs
    s" scenes.f" included
    scene# load
;

: save  ( - )
    \ save tilemaps, tile attributes, and objects  (layer settings are defined in scenes.f)
    the-scene [[
        my iol-path save-iol
        4 0 do i s.layer [[
            l.zstm @ if
                l.zstm newfile[
                    s" STMP" write 
                    i bgp [[
                        tm.cols sp@ 2 write drop
                        tm.rows sp@ 2 write drop
                        tm.base tm.stride tm.rows * write
                    ]]
                ]file
                l.zbmp @ if
                    my tad-path newfile[
                        0 l.bmp# tileattrs /tileattrs write
                    ]file
                then
            then
        ]] loop
    ]]
    cr ." DATA SAVED."
;

: randomize
    the-base a!
    256 256 * 0 do 8 rnd 4 rnd pack-tile !+ loop
;
randomize

: selw*  tile-selection 2 cells + @ * ;
: selh*  tile-selection 3 cells + @ * ;
        
: draw-cursor
    the-plane [[ 
        tile-selection 2@ swap 2s>f tilexy scroll- fover tm.tw f>s selw* s>f f+ fover tm.th f>s selh* s>f f+
        0e 0e 0e 0.5e al_draw_filled_rectangle ]]
\    tile#  the-plane
\        maus 2s>f colrow tilexy scroll- 1e f- fswap 1e f- fswap draw-tile
    tbrush [[
        the-plane 's tm.bmp# tm.bmp#!
        the-plane 's tm.tw tm.tw!
        the-plane 's tm.th tm.th!
        the-plane [[ maus 2s>f colrow tilexy scroll- 1e f- fswap 1e f- fswap ]] xy!
        draw-as-tilemap ]]    
;

: +sel  ( x y )
    swap tile-selection 8 + 2@ 2+ 1 max 128 min swap 1 max 128 min swap tile-selection 8 + 2! ;
                

: tw  the-plane 's tm.tw f>s ;
: th  the-plane 's tm.th f>s ;

: ?refresh
    the-bmp# zbmp-file mtime@ the-bmp# bmp-mtime @ > if 50 ms load-data then
;

: pan
    walt scrolly swap 2 / - 0 max the-scene 's s.h f>s viewh - min scrolly!
         scrollx swap 2 / - 0 max the-scene 's s.w f>s vieww - min scrollx!
;

: draw-plane  [[ scrollx s>f tm.scrollx! s>f scrolly tm.scrolly! draw-as-tilemap ]] ;

: draw-parallax dup the-scene 's s.layer >r
    bgp [[ scrollx s>f r@ 's l.parax f* tm.scrollx!
           scrolly s>f r> 's l.paray f* tm.scrolly! draw-as-tilemap ]]
;


:while maped update
    2x grey cls
    the-plane draw-plane 
    draw-cursor
    info if
        2x
        0 viewh 8 - at
        zstr[ ." Layer #" layer# 1 + . scrollx . scrolly . ]zstr print 
    then
;

: (tselect)  tile-selection 2@ swap tile-selection 8 + 2@ swap select-tiles ;

0 value startx 0 value starty
: shift-select
    shift? if
        lb-pressed if mouse to starty to startx then
        ms0 1 al_mouse_button_down if
            there tile-selection 2@ swap 2- 1 1 2+ swap tile-selection 8 + 2!
        then
        lb-letgo if display startx starty al_set_mouse_xy
            there swap tile-selection 2! then
    then
    ms0 1 al_mouse_button_down 0= if
        there swap tile-selection 2!
    then
;

:while maped step
    shift-select
    ms0 1 al_mouse_button_down 0<> shift? not and if
        <SPACE> held  if
            pan
        else
\            tile#
\                maus th / the-stride * swap tw / cells + the-base + !
            paste-tiles
        then 
    then
    ms0 2 al_mouse_button_down if
        maus th / the-stride * swap tw / cells + the-base + @ tile#!
    then
    ctrl? not shift? not and if 
        <e> pressed if -1 tile#! then
        <h> pressed if tile# $01000000 xor tile#! then
        <v> pressed if tile# $02000000 xor tile#! then
        <1> pressed if 0 to layer# then
        <2> pressed if 1 to layer# then
        <3> pressed if 2 to layer# then
        <4> pressed if 3 to layer# then
    then
    ctrl? if
        <c> pressed if (tselect) copy-tiles then
        <e> pressed if (tselect) erase-tiles then
        <x> pressed if (tselect) cut-tiles then
    then
;

: ?changesel
    etype ALLEGRO_EVENT_KEY_CHAR = if
        shift? if
            <up>    keycode = if 0 -1 +sel then
            <down>  keycode = if 0 1 +sel then
            <left>  keycode = if -1 0 +sel then
            <right> keycode = if 1 0 +sel then
        then
    then
;

:while maped pump
\    ?changesel
;

: tcols  the-plane [[ tm.bmp# bmp bmpw tm.tw f>s / ]] ; 
: mouse-tile  the-plane [[ mouse 2 / tm.th f>s / tcols *   swap 2 / tm.tw f>s /   + ]] ;

:while tiles update
    2x black cls
    0e 0e the-bmp# bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    the-bmp# bmp 0e 0e 0 al_draw_bitmap
    draw-cursor
    info if
        0 viewh 8 - at   zstr[ mouse-tile . ]zstr print
    then
;

:while tiles step
    shift-select
    the-bmp# bmp if
        ms0 1 al_mouse_button_down if
            mouse-tile tile-selection 8 + 2@ swap pick-tiles
            ( 1 1 tile-selection 8 + 2! )
        then
        ms0 2 al_mouse_button_down if
            mouse-tile tile#!
        then
    then
;
:while tiles pump
\    ?changesel
;

:while attributes update
    2x black cls
    0e 0e the-bmp# bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    the-bmp# 0= if exit then
    the-bmp# bmp 0e 0e 0 al_draw_bitmap
    the-plane [[
        0
        tm.bmp# bmp bmph 0 do
            tm.bmp# bmp bmpw 0 do
                dup tm.bmp# tileflags
                if i s>f j s>f fover tm.tw f+ fover tm.th f+ 0e 1e 1e 0.5e al_draw_filled_rectangle then
                1 +
            tm.tw f>s +loop
        tm.th f>s +loop
        drop
    ]]
;

: nand  invert and ;

:while attributes step
    the-bmp# 0= if exit then
    mouse 2 / the-bmp# bmp bmph < swap 2 / the-bmp# bmp bmpw < and if
        ms0 1 al_mouse_button_down if
            the-plane [[ mouse-tile tm.bmp# 2dup tileflags 1 or -rot tileflags! ]]
        then
        ms0 2 al_mouse_button_down if
            the-plane [[ mouse-tile tm.bmp# 2dup tileflags 1 nand -rot tileflags! ]]
        then
    then
;

: hue  1e frnd 1e frnd 1e frnd ;
: .prefab  zstr[ ." Prefab: #" prefab# . prefab# sdata count type ]zstr print ;
0 value mcounter
0 value click

:while objed update
    2x black cls
    0 draw-parallax
    1 draw-parallax
    
    m scrollx negate s>f zoom f* scrolly negate s>f zoom f* al_translate_transform
    m al_use_transform
    max-objects 0 do
        i object [[ en if
            id RandSeed !
            x y iw s>f x f+ ih s>f y f+ hue
                selected me = if counter 16 and if 1e else 0.5e then else 0.5e then
                al_draw_filled_rectangle
        then ]]
    loop
    draw-sprites
    info if
        2x
        0 viewh 8 - at   zstr[ scrollx . scrolly . ]zstr print 
        128 viewh 8 - at  .prefab
    then
;

: ?snap ( obj )
    [[ snapping if
        x the-plane 's tm.tw 2e f/ f/ fround the-plane 's tm.tw 2e f/ f* x!
        y the-plane 's tm.th 2e f/ f/ fround the-plane 's tm.th 2e f/ f* y!
    then ]]
;


: ?drag
    maus | my mx |
    dragging if
        ms0 1 al_mouse_button_down selected 0<> and
            selected hovered = and if
            selected [[ walt s>f 2e f/ y f+ y! s>f 2e f/ x f+ x! ]]
        then
        ms0 1 al_mouse_button_down 0= if
            false to dragging
            selected ?snap
        then
    else
        0 to hovered
        max-objects 0 do
            i object [[ en if
                mx x f>s >= my y f>s >= and
                mx x f>s iw + <= and my y f>s ih + <= and if
                    me to hovered
                    ms0 1 al_mouse_button_down if
                        me to selected
                        true to dragging
                    then
                    ms0 2 al_mouse_button_down if
                        objtype to prefab#
                    then
                then
            then ]]
        loop
    
    then
;

:while objed step
    alt? not to snapping
    
    \ ms0 1 al_mouse_button_down if
    \     1 +to mcounter
    \ then
    \ 
    \ mcounter 10 < if
    \     lb-letgo if
    \         0 to mcounter
    \         -1 to click
    \         ." Click! "
    \     then
    \ else
        <SPACE> held ms0 1 al_mouse_button_down and if
            pan exit
        then
            
        ?drag
    \ then
    
    <a> pressed ctrl? and if
        maus at prefab# one-object to selected
        selected ?snap
    then
    
    <del> pressed if
        selected 's en if selected dismiss then
        0 to selected
    then
;
:while objed pump
    etype ALLEGRO_EVENT_KEY_CHAR = if
        <q> keycode = if prefab# 1 - 255 and to prefab# then
        <w> keycode = if prefab# 1 + 255 and to prefab# then
    then
;

: 1x      m al_identity_transform      m al_use_transform ;

:while objsel update
    1x 0e 0e 1e color cls
\    m scrollx negate s>f scrolly negate s>f al_translate_transform
    prefab# prefab [[ en if
        counter 16 and if
            x 1e f- y 1e f- iw s>f x f+ 1e f+ ih s>f y f+ 1e f+
                1e 0e 0e 1e al_draw_filled_rectangle
        then
    then ]]
    max-objects 0 do
        i prefab [[ en if bmp# draw-as-sprite then ]]
    loop
;

:while objsel step
;

: system
    ?refresh
    1 +to counter
    <f4> pressed alt? and if bye then
    <f1> pressed if maped then
    <f2> pressed if tiles then
    <f3> pressed if objed then
    <f4> pressed if objsel then
    <f5> pressed if load-data then
    <f8> pressed if attributes then
    <s> pressed ctrl? and if save then
    <i> pressed if info not to info then
\    <s> pressed ctrl? not and if snapping not to snapping then
;

: init-game
    cr
    cr ." F1     F2     F3     F4     F5     F6     F7     F8     F9    F10    F11    F12    "
    cr ." MAPED  TILES  OBJED         RELOAD               ATTR "
    cr ." Ctrl+S = Save everything "
    cr ." i = toggle info "
    cr
    cr ." --== MAP ==-- "
    cr ." e = eraser"
    cr ." 1-4 = select layer"
    cr ." R-click = pick tile"
    cr ." Shift+up/down/left/right = modify selection (temporary)"
\    cr ." Shift+Drag = select"
    cr ." space+Drag = pan"
    cr ." CTRL+C, CTRL+X = get brush"
    cr ." CTRL+E = erase selection"
\    cr ." CTRL+F = fill selection with brush"
\    cr ." h/v = flip brush"
    maped
;

include lib/gl1post

export [if] turnkey editor [then]  \ turnkey (save) breaks reloading
init