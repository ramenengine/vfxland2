require lib/filelib.f
require utils.f
require lib/a.f

256 256 plane: lyr1 1 tm.bmp#! ;plane
256 256 plane: lyr2 1 tm.bmp#! ;plane
256 256 plane: lyr3 1 tm.bmp#! ;plane
256 256 plane: lyr4 1 tm.bmp#! ;plane

0 value tcols
0 value b

\ internal scene struct
0
    32 zgetset s.zname s.zname!
    64 zgetset s.zstm1 s.zstm1!
    64 zgetset s.zstm2 s.zstm2!
    64 zgetset s.zstm3 s.zstm3!
    64 zgetset s.zstm4 s.zstm4!
    fgetset s.w s.w!      \ bounds
    fgetset s.h s.h!
constant /scene

/scene 200 array scene

: (convert)  ( n h v - n )
    1 lshift or 24 lshift swap
    tcols /mod 8 lshift or
    or
;

: ?exist
    dup zcount file-exists not if dup cr zcount type ." not found" 0 else 1 then
;

: load-stm ( zstr layer -- )
    {{ ?exist if file[ 
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
    ]file then }} 
;

: load-iol ( zstr -- )
    ?exist if file[
        0 object bytes-left read 
    ]file then
;

: save-iol ( zstr -- )
    newfile[
        0 object [ lenof object ]# /objslot * write
    ]file 
;


: clear-layer  ( layer -- )
    {{ tm.base  tm.dims * cells  erase  }} ;

: scene:  ( i - <name> ) ( - n )
    >in @ >r
    dup constant scene {{
    r> >in ! bl parse s>z s.zname!
;

: ;scene }} ;

: iol  s.zname z$ z+" .iol" ;

: load  ( n )
    scene {{
    s.zstm1 dup @ if lyr1 load-stm else lyr1 clear-layer then
    s.zstm2 dup @ if lyr2 load-stm else lyr2 clear-layer then
    \ iol load-iol
    }}
;

 