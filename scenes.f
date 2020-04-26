0 scene: test
    64 16 * s>f fdup s.h! s.w!
    0 s.layer [[
        1 l.bmp#!
        0.25e l.parax! 0.25e l.paray!
        z" data/test.tiles.png" l.zbmp!
        z" data/levels/test.test.layer-1.map001.stm" l.zstm!
    ]]
    1 s.layer [[
        1 l.bmp#!
        z" data/levels/test.test.layer-2.map001.stm" l.zstm!
    ]]
;scene

1 scene: scene1
    0 s.layer [[
        1 l.bmp#!
        z" data/levels/scene1.layer-1.stm" l.zstm!
    ]]
    1 s.layer [[
        1 l.bmp#!
        z" data/levels/scene1.layer-2.stm" l.zstm!
    ]]
;scene