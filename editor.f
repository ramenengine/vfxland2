0 value a
: a!  to a ;
: !+  a !  cell +to a ;


( maybe pass in the dimensions and source address on the stack ... )

256 256 plane plane1
8e tm.tw! 8e tm.th!
1 tm.bmp!
tm.base constant data

0 value tile


: randomize
    data a!
    256 256 * 0 do 72 rnd !+ loop
;

randomize

:make load-data
    1 z" data/gomolabg.png" load-bitmap
;

:make bg
    plane1 {{ draw-as-tilemap }} 
;

:make pump
    etype ALLEGRO_EVENT_MOUSE_BUTTON_DOWN = if
        cr
        alevt MOUSE_EVENT.x ?
        alevt MOUSE_EVENT.y ?
        alevt MOUSE_EVENT.button ?
    then
;

: mouse  ms0 0 al_get_mouse_state_axis ms0 1 al_get_mouse_state_axis ;

:make step
    ms0 1 al_mouse_button_down if
        tile
        mouse 2 / 8 / 256 * swap 2 / 8 / + cells data + !
    then
    ms0 2 al_mouse_button_down if then
    ms0 3 al_mouse_button_down if then
;

plane1 to me

warm
