empty only forth definitions
\ true constant fullscreen
require gamelib1.f
require keys.f
require lib/filelib.f
require utils.f
require scene.f
require input.f
include scenes
include objects

:make load-data
    0 z" data/lemming.png" load-bitmap
    1 z" data/test.tiles.png" load-bitmap
    0 load
;

:make bg
    lyr1 {{ draw-as-tilemap }} 
    lyr2 {{ draw-as-tilemap }} 
;

:make fg
    draw-sprites
;

:hook game step
    max-objects 0 do
        i object {{ en if
            think  x vx f+ x!  y vy f+ y!
        then }}        
    loop
;

0 object as
`lemming become
100e 150e xy!

warm