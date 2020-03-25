require gamelib1.f
require keys.f
require lib/filelib.f
require utils.f
require scene.f

:make load-data
    0 z" data/lemming.png" load-bitmap
    1 z" data/test.tiles.png" load-bitmap
    0 load
;

0 scene: test
    z" data/test.test.layer-1.map001.stm" s.zstm1 zmove
    z" data/test.test.layer-2.map001.stm" s.zstm2 zmove
    320e s.w! 240e s.h!
;scene

:make bg
    lyr1 {{ draw-as-tilemap }} 
    lyr2 {{ draw-as-tilemap }} 
;
:make fg
    draw-sprites
;

warm