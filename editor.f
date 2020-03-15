require keys

0 value a
: a!  to a ;
: !+  a !  cell +to a ;

: kdown  kbs0 swap al_key_down ;
: kup    kdown not ;
: kdelta dup kdown kbs1 rot al_key_down - ;
: kpress   kdelta 1 = ;
: krel     kdelta -1 = ;
: shift? 215 kdown 216 kdown or ;
: ctrl? 217 kdown 218 kdown or ;
: alt?  219 kdown 220 kdown or ;
: mouse  ms0 0 al_get_mouse_state_axis ms0 1 al_get_mouse_state_axis ;
: mickey ms1 0 al_get_mouse_state_axis ms1 1 al_get_mouse_state_axis ;
: 2-  rot swap - >r - r> ;
: walt   mouse mickey 2- ;


( maybe pass in the dimensions and source address on the stack ... )

256 256 plane edplane
8e tm.tw! 8e tm.th!
1 tm.bmp!
tm.base constant data
0 value tile
0 value ts-mtime  \ last time tileset's bitmap was modified
lenof bitmap 256 array zbmp-file
lenof bitmap cell array bmp-mtime

: randomize
    data a!
    256 256 * 0 do 72 rnd !+ loop
;
randomize

: mtime@
    al_create_fs_entry >r
    r@ al_get_fs_entry_mtime 
    r> al_destroy_fs_entry 
;

: load-bitmap  ( i zstr - )
    2dup
    2dup load-bitmap
    zcount rot zbmp-file swap 1 + move
    ( i zstr ) mtime@ swap bmp-mtime !
;

:make load-data
    1 z" data/gomolabg.png" load-bitmap
;

:make bg
    edplane {{ draw-as-tilemap }} 
;

:make pump
    etype ALLEGRO_EVENT_MOUSE_BUTTON_DOWN = if
        cr
        alevt MOUSE_EVENT.x ?
        alevt MOUSE_EVENT.y ?
        alevt MOUSE_EVENT.button ?
    then
;

: 2+  rot + >r + r> ;
: maus  mouse 2 / swap 2 / swap edplane {{ tm.scrollx f>s tm.scrolly f>s }} 2+ ;
: tw  edplane {{ tm.tw }} f>s ;
: th  edplane {{ tm.th }} f>s ;

: ?refresh
    1 zbmp-file mtime@ 1 bmp-mtime @ > if 50 ms load-data then
;

:make step
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


warm
