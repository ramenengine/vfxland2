empty only forth definitions
include lib/gl1pre
require keys.f
require input.f
require lib/strout.f
require lib/a.f
require scene.f
require script.f

0 value tile#
true value info
0 value scene#
0 value layer#
true value snapping
0 value selected  \ object
0 value hovered   \ object
0 value counter
0 value dragging  \ bool

screen map
screen tiles
screen attributes
screen objed
screen objsel

: scn  scene# scene ;
: scn-lyr  scene# scene [[ layer# s.layer ]] ;
: edplane  layer# lyr ;
: data  edplane 's tm.base ;
: ed-stride  edplane 's tm.stride ;

: load  ( scene# )
    dup to scene#
    load  \ load tilemaps, tile attributes, layer settings, and objects from given scene
    
    \ load tileset(s)
    scn [[
        4 0 do i s.layer [[ l.bmp# l.zbmp load-bitmap ]] loop
    ]]
    \ copy the layer properties from the scene layer to the engine layer
    scn-lyr   [[ l.tw l.th l.scrollx l.scrolly l.bmp# ]]
    edplane   [[ tm.bmp#! tm.scrolly! tm.scrollx! tm.th! tm.tw! ]]
;

: load-data
    s" data.f" included
    s" scenes.f" included
    s" scripts.f" included
    scene# load
;

: save  ( - )
    \ save tilemaps, tile attributes, and objects  (layer settings are defined in scenes.f)
    scn [[
        my iol-path save-iol
        4 0 do i s.layer [[
            l.zstm @ if
                l.zstm newfile[
                    s" STMP" write 
                    i lyr [[
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
;

: randomize
    data a!
    256 256 * 0 do 8 rnd 4 rnd pack-tile !+ loop
;
randomize

: bmpwh dup al_get_bitmap_width swap al_get_bitmap_height ;
: ed-bmp#  edplane 's tm.bmp# ;

: 2+  rot + >r + r> ;

\        fmouse >v zoom uv/ edplane 's scrollxy v+ v>
\        >v tm.twh v/ vtrunc v>
\        >v tm.twh v* v>
\        >v scrollxy v- v>

\        fmouse >v zoom uv/ edplane 's scrollxy v+
\        tm.twh v/ vtrunc tm.twh v* scrollxy v- v>

: maus  mouse zoom f>s / swap zoom f>s / swap edplane [[ tm.scrollx f>s tm.scrolly f>s ]] 2+ ;
: colrow  fswap tm.tw f/ ftrunc fswap tm.th f/ ftrunc ;
: tilexy  fswap tm.tw f* fswap tm.th f* ;
: scroll-  fswap tm.scrollx f- fswap tm.scrolly f- ;

: draw-cursor
    edplane [[ 
    tile#  edplane
        maus 2s>f colrow tilexy scroll- 1e f- fswap 1e f- fswap draw-tile
]] ;

: scroll$  zstr[ edplane [[ tm.scrollx f>s . tm.scrolly f>s . ]] ]zstr ;

:while map update
    2x
    0.5e 0.5e 0.5e 1e al_clear_to_color
    edplane [[ draw-as-tilemap ]]
    draw-cursor
    info if 
        bif 1e 1e 1e 1e 0e viewh 8 - s>f 0 scroll$ al_draw_text
    then
;

:while map pump
    etype ALLEGRO_EVENT_MOUSE_BUTTON_DOWN = if
\        cr
\        alevt MOUSE_EVENT.x ?
\        alevt MOUSE_EVENT.y ?
\        alevt MOUSE_EVENT.button ?
    then
;

: tw  edplane [[ tm.tw ]] f>s ;
: th  edplane [[ tm.th ]] f>s ;

: ?refresh
    ed-bmp# zbmp-file mtime@ ed-bmp# bmp-mtime @ > if 50 ms load-data then
;

:while map step
    ms0 1 al_mouse_button_down if
        <SPACE> held  if
            edplane [[
                walt tm.scrolly s>f f- 0e fmax tm.scrolly!
                    tm.scrollx s>f f- 0e fmax tm.scrollx!
            ]]
        else
            tile#
                maus th / ed-stride * swap tw / cells + data + !
        then 
    then
    ms0 2 al_mouse_button_down if
        maus th / ed-stride * swap tw / cells + data + @ to tile#
    then
    ms0 3 al_mouse_button_down if then
    <e> pressed if -1 to tile# then
    <h> pressed if tile# $01000000 xor to tile# then
    <v> pressed if tile# $02000000 xor to tile# then
    <i> pressed if info not to info then
    <1> pressed if 0 to layer# then
    <2> pressed if 1 to layer# then
    <3> pressed if 2 to layer# then
    <4> pressed if 3 to layer# then
;

:while tiles update
    2x cls
    0e 0e ed-bmp# bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    ed-bmp# bmp 0e 0e 0 al_draw_bitmap
    draw-cursor
    100000 0 do loop \ fsr fixes choppiness
;

: tcols  edplane [[ tm.bmp# bmp bmpw tm.tw f>s / ]] ; 
: mouse-tile  edplane [[ mouse 2 / tm.th f>s / tcols *   swap 2 / tm.tw f>s /   + ]] ;

:while tiles step
    ms0 1 al_mouse_button_down if
        mouse-tile to tile#
    then
;

:while attributes update
    2x cls
    0e 0e ed-bmp# bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    ed-bmp# 0= if exit then
    ed-bmp# bmp 0e 0e 0 al_draw_bitmap
    edplane [[
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
            edplane [[ mouse-tile tm.bmp# 2dup tileflags 1 or -rot tileflags! ]]
        then
        ms0 2 al_mouse_button_down if
            edplane [[ mouse-tile tm.bmp# 2dup tileflags 1 nand -rot tileflags! ]]
        then
    then
;

: hue  1e frnd 1e frnd 1e frnd ;

:while objed update
    2x cls
    lyr1 [[ draw-as-tilemap ]]
    lyr2 [[ draw-as-tilemap ]]
    1 RandSeed !
    max-objects 0 do
        i object [[ en if
            x y iw s>f x f+ ih s>f y f+ hue
                selected me = if counter 16 and if 1e else 0.5e then else 0.5e then
                al_draw_filled_rectangle
        then ]]
    loop
    draw-sprites
;

:while objed step
    maus | my mx |
    <s> pressed ctrl? not and if snapping not to snapping then

    dragging if
        ms0 1 al_mouse_button_down selected 0<> and
            selected hovered = and if
            selected [[ walt s>f 2e f/ y f+ y! s>f 2e f/ x f+ x! ]]
        then
        ms0 1 al_mouse_button_down 0= if
            false to dragging
            snapping if
                selected 's x edplane 's tm.tw 2e f/ f/ fround edplane 's tm.tw 2e f/ f* selected 's x!
                selected 's y edplane 's tm.th 2e f/ f/ fround edplane 's tm.th 2e f/ f* selected 's y!
            then
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
                then
            then ]]
        loop
    
    then

;    

: system
    ?refresh
    <f1> pressed if map then
    <f2> pressed if tiles then
    <f3> pressed if attributes then
    <f5> pressed if load-data then
    <f11> pressed if objed then
    <f12> pressed if objsel then
    <s> pressed ctrl? and if save then
    1 +to counter
;

include lib/gl1post

cr
cr .( F1     F2     F3     F4     F5     F6     F7     F8     F9    F10    F11    F12    ) \ "
cr .( MAP    TILES  ATTRS         RELOAD                                   OBJED  OBJSEL ) \ "
cr .( Ctrl+S = Save everything ) \ "
cr
cr .( --== MAP ==-- ) \ "
cr .( i = toggle info ) \ "
map
init