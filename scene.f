require lib/filelib.f
require utils.f
require lib/a.f

256 256 plane: lyr1 1 tm.bmp#! ;plane
256 256 plane: lyr2 1 tm.bmp#! ;plane

0 value tcols
0 value b

0
    64 buffer s.zstm1
    64 buffer s.zstm2
    64 buffer s.ziol      \ initial object list path
\    64 buffer s.zods     \ object descriptions script path
    fgetset s.w s.w!      \ bounds
    fgetset s.h s.h!
constant /scene

/scene 200 array scene

: (convert)  ( n h v - n )
    1 lshift or 24 lshift swap
    tcols /mod 8 lshift or
    or
;
 
: load-stm ( zstr layer -- )
    {{ file[ 
        0 sp@ 4 read drop
        0 sp@ 2 read ( w ) dup tm.cols! cells tm.stride!
        0 sp@ 2 read ( h ) tm.rows!
        tm.base  bytes-left read
        tm.bmp# bmp ?dup 0= abort" Tilemap's referenced bitmap is null!"
            to b
        b bmpw tm.tw f>s / to tcols
        tm.base  tm.dims * cells bounds do
            i @ 0 <> if 
                i w@ i 2 + c@ i 3 + c@ (convert) i !
            then
        cell +loop 
    ]file }} 
;

: load-iol ( zstr -- )
    file[
        0 object bytes-left read 
    ]file 
;

: clear-layer  ( layer -- )
    {{ tm.base  tm.dims * cells  erase  }} ;

: scene:  ( i - <name> ) ( - n )
    dup constant scene {{
;

: ;scene }} ;

: load  ( n )
    scene {{
    s.zstm1 dup @ if lyr1 load-stm else lyr1 clear-layer then
    s.zstm2 dup @ if lyr2 load-stm else lyr2 clear-layer then
    s.ziol dup @ if load-iol else drop then
    \ s.zods dup @ if zcount included else drop then
    }}
;

