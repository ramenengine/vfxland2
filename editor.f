include gamelib1
require keys.f
require input.f
include dev

Module editor

0 value a
: a!  to a ;
: !+  a !  cell +to a ;

( maybe pass in the dimensions and source address on the stack ... )

256 256 plane edplane
16e tm.tw! 16e tm.th!
1 tm.bmp!
tm.base constant data
0 value tile

screen map

: randomize
    data a!
    256 256 * 0 do 8 rnd 8 rnd 4 rnd packtile !+ loop
;
randomize

:hook map update
    2x
    0.5e 0.5e 0.5e 1e al_clear_to_color
    edplane {{ draw-as-tilemap }} 
;

:hook map pump
    etype ALLEGRO_EVENT_MOUSE_BUTTON_DOWN = if
\        cr
\        alevt MOUSE_EVENT.x ?
\        alevt MOUSE_EVENT.y ?
\        alevt MOUSE_EVENT.button ?
    then
;

: 2+  rot + >r + r> ;
: maus  mouse 2 / swap 2 / swap edplane {{ tm.scrollx f>s tm.scrolly f>s }} 2+ ;
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
            tile
                 maus th / 256 * swap tw / + cells data + !
        then 
    then
    ms0 2 al_mouse_button_down if then
    ms0 3 al_mouse_button_down if then
;

:make system
    <f1> press if map then
    <f5> press if game then
;

EXPORT edplane
EXPORT map

End-Module

include main
map

cr
cr .( F1     F2     F3     F4     F5     F6     F7     F8 )
cr .( MAP    TILES  OBJS          GAME                    )
warm