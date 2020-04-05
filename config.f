
: load-data
    0 z" data/lemming.png" load-bitmap
    1 z" data/test.tiles.png" load-bitmap
    0 load
;

:while game update
    2x cls 
    lyr1 [[ draw-as-tilemap ]] 
    lyr2 [[ draw-as-tilemap ]] 
    draw-sprites
;

:while game step
    max-objects 0 do
        i object [[ en if
            think  x vx f+ x!  y vy f+ y!
        then ]]        
    loop
;