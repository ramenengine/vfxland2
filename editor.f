include gamelib1
include dev

require keys.f
require input.f
require lib/strout.f
require lib/a.f

( maybe pass in the dimensions and source address on the stack ... )

256 256 plane edplane
16e tm.tw! 16e tm.th!
1 tm.bmp!
tm.base constant data
0 value tile
true value info

screen map
screen tiles

: randomize
    data a!
    256 256 * 0 do 8 rnd 8 rnd 4 rnd packtile !+ loop
;
randomize

: 2+  rot + >r + r> ;
: maus  mouse 2 / swap 2 / swap edplane {{ tm.scrollx f>s tm.scrolly f>s }} 2+ ;

: draw-cursor
    edplane {{ 
    tile edplane
        mouse swap s>f zoom f/ tm.tw 2e f/ f-
              s>f zoom f/ tm.th 2e f/ f- draw-tile
}} ;

: scroll$  zstr[ edplane {{ tm.scrollx f>s . tm.scrolly f>s . }} ]zstr ;

:hook map update
    2x
    0.5e 0.5e 0.5e 1e al_clear_to_color
    edplane {{ draw-as-tilemap }}
    draw-cursor
    info if 
        bif 1e 1e 1e 1e 0e viewh 8 - s>f 0 scroll$ al_draw_text
    then
;

:hook map pump
    etype ALLEGRO_EVENT_MOUSE_BUTTON_DOWN = if
\        cr
\        alevt MOUSE_EVENT.x ?
\        alevt MOUSE_EVENT.y ?
\        alevt MOUSE_EVENT.button ?
    then
;

: tw  edplane {{ tm.tw }} f>s ;
: th  edplane {{ tm.th }} f>s ;

: ?refresh
    1 zbmp-file mtime@ 1 bmp-mtime @ > if 50 ms load-data then
;

:hook map step
    ?refresh
    ms0 1 al_mouse_button_down if
        <SPACE> kdown  if
            edplane {{
                walt tm.scrolly s>f f- 0e fmax tm.scrolly!
                    tm.scrollx s>f f- 0e fmax tm.scrollx!
            }}
        else
            alt? if
                maus th / 256 * swap tw / + cells data + @ to tile
            else
                tile
                 maus th / 256 * swap tw / + cells data + !
            then
        then 
    then
    ms0 2 al_mouse_button_down if then
    ms0 3 al_mouse_button_down if then
    <e> press if -1 to tile then
    <h> press if tile $01000000 xor to tile then
    <v> press if tile $02000000 xor to tile then
    <i> press if info not to info then
;

: bmpwh dup al_get_bitmap_width swap al_get_bitmap_height ;

:hook tiles update
    2x cls
    0e 0e 1 bmp bmpwh swap s>f s>f
        1e 0e 1e 1e al_draw_filled_rectangle
    1 bmp 0e 0e 0 al_draw_bitmap
    draw-cursor
    100000 0 do loop \ fsr fixes choppiness
;

:hook tiles step
    ?refresh
    ms0 1 al_mouse_button_down if
        edplane {{
            mouse 2 / tm.th f>s / 8 lshift
                swap 2 / tm.tw f>s /  or  to tile
        }}
    then
;

:make system
    <f1> press if map then
    <f2> press if tiles then
\    <f5> press if game then
;

map

cr
cr .( F1     F2     F3     F4     F5     F6     F7     F8 )
cr .( MAP    TILES                                        )
cr
cr .( --== MAP ==-- )
cr .( i = toggle info )

warm