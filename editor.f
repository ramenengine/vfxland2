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

0 value tile#
true value info
0 value scene#
0 value layer#
true value snapping
0 value selected  \ object
0 value hovered   \ object
0 value counter
0 value dragging  \ bool
0 value prefab#

/screen
    screen-getset scrollx scrollx!
    screen-getset scrolly scrolly!
to /screen

screen maped
screen tiles
screen attributes
screen objed
screen objsel

: black  0e 0e 0e color 1e alpha ;
: grey   0.5e 0.5e 0.5e color 1e alpha ;

: the-scene  scene# scene ;
: the-layer  scene# scene [[ layer# s.layer ]] ;
: the-plane  layer# bgp ;
: the-base   the-plane 's tm.base ;
: the-stride the-plane 's tm.stride ;

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

: bmpwh dup al_get_bitmap_width swap al_get_bitmap_height ;
: ed-bmp#  the-plane 's tm.bmp# ;

\        fmouse >v zoom uv/ the-plane 's scrollxy v+ v>
\        >v tm.twh v/ vtrunc v>
\        >v tm.twh v* v>
\        >v scrollxy v- v>

\        fmouse >v zoom uv/ the-plane 's scrollxy v+
\        tm.twh v/ vtrunc tm.twh v* scrollxy v- v>

: maus  mouse zoom f>s / swap zoom f>s / swap scrollx scrolly 2+ ;
: colrow  fswap tm.tw f/ ftrunc fswap tm.th f/ ftrunc ;
: tilexy  fswap tm.tw f* fswap tm.th f* ;
: scroll-  fswap scrollx s>f f- fswap scrolly s>f f- ;

: draw-cursor
    the-plane [[ 
    tile#  the-plane
        maus 2s>f colrow tilexy scroll- fover 16e f+ fover 16e f+ 0e 0e 0e 0.5e al_draw_filled_rectangle
        maus 2s>f colrow tilexy scroll- 1e f- fswap 1e f- fswap draw-tile
]] ;

: tw  the-plane 's tm.tw f>s ;
: th  the-plane 's tm.th f>s ;

: ?refresh
    ed-bmp# zbmp-file mtime@ ed-bmp# bmp-mtime @ > if 50 ms load-data then
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

: .scroll  zstr[ scrollx . scrolly . ]zstr print ;

:while maped update
    2x grey cls
    the-plane draw-plane 
    draw-cursor
    info if
        2x
        0 viewh 8 - at   .scroll
    then
;

:while maped step
    ms0 1 al_mouse_button_down if
        <SPACE> held  if
            pan
        else
            tile#
                maus th / the-stride * swap tw / cells + the-base + !
        then 
    then
    ms0 2 al_mouse_button_down if
        maus th / the-stride * swap tw / cells + the-base + @ to tile#
    then
    ms0 3 al_mouse_button_down if then
    <e> pressed if -1 to tile# then
    <h> pressed if tile# $01000000 xor to tile# then
    <v> pressed if tile# $02000000 xor to tile# then
    <1> pressed if 0 to layer# then
    <2> pressed if 1 to layer# then
    <3> pressed if 2 to layer# then
    <4> pressed if 3 to layer# then
;

:while tiles update
    2x black cls
    0e 0e ed-bmp# bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    ed-bmp# bmp 0e 0e 0 al_draw_bitmap
    draw-cursor
    100000 0 do loop \ fsr fixes choppiness
;

: tcols  the-plane [[ tm.bmp# bmp bmpw tm.tw f>s / ]] ; 
: mouse-tile  the-plane [[ mouse 2 / tm.th f>s / tcols *   swap 2 / tm.tw f>s /   + ]] ;

:while tiles step
    ms0 1 al_mouse_button_down if
        mouse-tile to tile#
    then
;

:while attributes update
    2x black cls
    0e 0e ed-bmp# bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    ed-bmp# 0= if exit then
    ed-bmp# bmp 0e 0e 0 al_draw_bitmap
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
    ed-bmp# 0= if exit then
    mouse 2 / ed-bmp# bmp bmph < swap 2 / ed-bmp# bmp bmpw < and if
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
        0 viewh 8 - at   .scroll
        96 0 +at  .prefab
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

: lb-letgo  ms1 1 al_mouse_button_down 0<> ms0 1 al_mouse_button_down 0= and ;

:while objed step

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
        alevt KEYBOARD_EVENT.keycode @ <q> = if prefab# 1 - 255 and to prefab# then
        alevt KEYBOARD_EVENT.keycode @ <w> = if prefab# 1 + 255 and to prefab# then
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
    cr ." MAPED  TILES  OBJED         RELOAD ATTR "
    cr ." Ctrl+S = Save everything "
    cr
    cr ." --== MAP ==-- "
    cr ." i = toggle info "
    maped
;

include lib/gl1post

export [if] turnkey editor [then]  \ turnkey (save) breaks reloading
init