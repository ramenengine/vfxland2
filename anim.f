pgetset counter counter!

: +counter counter + counter! ;

: anim:  create here 0 , ;

: ;anim  here over cell+ - cell/ swap ! ;

( TODO: could be optimized with a "bmpcols" array )

: aframe  ( .counter anim - ix iy )
    swap p>s | frame# anim |
    anim cell+ frame# anim @ mod cells + @
    bmp# bitmap @ bmpw iw / /mod ih * swap iw * swap 
;

: ixy!  iy! ix! ;

: animate  ( anim .speed - )
    swap +counter   counter swap aframe ixy! ;
