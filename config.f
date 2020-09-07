
: load-data
    0 z" data/lemming.png" load-bitmap
    1 z" data/test.tiles.png" load-bitmap
    0 load
;

:while game update
    2x cls 
    bgp1 [[ draw-as-tilemap ]] 
    bgp2 [[ draw-as-tilemap ]] 
    paint
;

:while game step
    max-objects 0 do
        i object [[ en if
            think  x vx + x!  y vy + y!
        then ]]
    loop
;