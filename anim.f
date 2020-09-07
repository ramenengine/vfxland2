pgetset counter counter!

: +counter counter + counter! ;

: anim:  create here 0 , ;

: ;anim  here over cell+ - cell/ swap ! ;

( TODO: could be optimized with a "bmpcols" array )

: frame  ( .counter adr - ix iy )
    dup @ >r cell+ swap p>s r> mod cells + @
    bmp# bitmap @ bmpw iw / /mod ih * swap iw * swap 
;

: ixy!  iy! ix! ;

