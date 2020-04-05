empty only forth definitions
include lib/gl1pre
require keys.f
require input.f
require lib/strout.f
require lib/a.f
require scene.f
include scenes

0 value tile#
true value info
0 value scene#
0 value layer#

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
        4 0 do i s.layer [[ tm.bmp# l.zbmp load-bitmap ]] loop
    ]]
    \ copy the layer from the scene into the engine, preserving base address and stride
    edplane 's tm.base edplane 's tm.stride 
        scn-lyr edplane /tilemap move
    edplane 's tm.stride! edplane 's tm.base!
;

: load-data
    scene# load
;

: save  ( - )
    \ save tilemaps, tile attributes, and objects  (layer settings are defined in scenes.f)
    scn [[
        4 0 do i s.layer [[
            l.zstm @ if l.zstm newfile[
                s" STMP" write 
                tm.cols sp@ 2 write drop
                tm.rows sp@ 2 write drop
                tm.base tm.cols cells tm.rows * write
            ]file then
        ]] loop
    ]]
;

screen map
screen tiles
screen attributes

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
    ?refresh
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
    <e> press if -1 to tile# then
    <h> press if tile# $01000000 xor to tile# then
    <v> press if tile# $02000000 xor to tile# then
    <i> press if info not to info then
    <1> press if 0 to layer# then
    <2> press if 1 to layer# then
    <3> press if 2 to layer# then
    <4> press if 3 to layer# then
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
    ?refresh
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
                if i s>f j s>f fover tm.tw f+ fover tm.th f+ 0e 1e 1e 0.1e al_draw_filled_rectangle then
                1 +
            tm.tw f>s +loop
        tm.th f>s +loop
        drop
    ]]
;

: nand  invert and ;

:while attributes step
    ?refresh
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

: system
    <f1> press if map then
    <f2> press if tiles then
    <f3> press if attributes then
    <f5> press if s" scenes.f" included then
;

include lib/gl1post

cr
cr .( F1     F2     F3     F4     F5     F6     F7     F8 ) \ "
cr .( MAP    TILES  ATTRS         RELOAD                  ) \ "
cr .( Ctrl+S = Save everything ) \ "
cr
cr .( --== MAP ==-- ) \ "
cr .( i = toggle info ) \ "
map
init