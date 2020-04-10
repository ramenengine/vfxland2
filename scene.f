require lib/filelib.f
require utils.f
require lib/a.f

256 256 plane: bgp1 1 tm.bmp#! ;plane
256 256 plane: bgp2 1 tm.bmp#! ;plane
256 256 plane: bgp3 1 tm.bmp#! ;plane
256 256 plane: bgp4 1 tm.bmp#! ;plane
create bgplanes bgp1 , bgp2 , bgp3 , bgp4 ,
: bgp  cells bgplanes + @ ;

1024 cells constant /tileattrs 

create tiledata /tileattrs lenof bitmap * /allot
: tileattrs  ( n bmp# - a ) 1024 * + cells tiledata + ;
\ keep the data struct abstracted away so we can add stuff (use other arrays)
: tileflags  ( n bmp# - n ) tileattrs @ ;
: tileflags! ( n n bmp# ) tileattrs ! ;

\ internal layer struct
0
    64 zgetset l.zstm l.zstm!       \ tilemap path
    64 zgetset l.zbmp l.zbmp!       \ tile bitmap path
    fgetset l.parax l.parax!
    fgetset l.paray l.paray!
    fgetset l.tw l.tw!              \ tile size
    fgetset l.th l.th!
    fgetset l.scrollx l.scrollx!    \ initial scroll coords in pixels
    fgetset l.scrolly l.scrolly!
    getset l.bmp# l.bmp#!
constant /LAYER

\ internal scene struct
0
    32 zgetset s.zname s.zname!
    fgetset s.w s.w!      \ bounds
    fgetset s.h s.h!
    4 /layer field[] s.layer
constant /SCENE

/scene 200 array scene
32 4096 cells array tiledata  \ attribute data

: init-layer  16e fdup l.th! l.tw! 1e fdup l.paray! l.parax!
    0e fdup l.scrolly! l.scrollx! ;

: ?exist
    dup zcount file-exists not if cr zcount type ."  not found" 0 else 1 then
;

: load-stm ( zstr tilemap -- )
    [[ ?dup if ?exist if file[ 
        0 sp@ 4 read drop
        0 sp@ 2 read ( w ) dup tm.cols! cells tm.stride!
        0 sp@ 2 read ( h ) tm.rows!
        tm.base  bytes-left read
    ]file then then ]] 
;

: load-iol ( zstr -- )
    ?dup if ?exist if file[
        0 object bytes-left read 
    ]file then then
;

: save-iol ( zstr -- )
    newfile[
        0 object  [ lenof object /objslot * ]#  write
    ]file 
;

: clear-tilemap  ( tilemap -- )
    [[ tm.base  tm.dims * cells  erase  ]] ;

: scene:  ( i - <name> ) ( - n )
    >in @ >r
    dup constant scene [[
    r> >in ! bl parse s>z s.zname!
    4 0 do i s.layer [[ init-layer ]] loop
;

: ;scene ]] ;

: iol-path  ( scene ) z" data/" z$ swap 's s.zname z+  +z" .iol" ;
: tad-path  ( layer ) 's l.zbmp zcount 4 - s>z +z" .tad" ;

: load  ( n )
    scene [[
        4 0 do i s.layer [[            
            l.zstm @ if
                l.zstm i bgp load-stm
                l.zbmp @ if 
                    my tad-path ?exist if file[ 0 l.bmp# tileattrs /tileattrs read ]file then
                then
            else i bgp clear-tilemap
            then            
        ]] loop
        my iol-path ?exist if load-iol then
    ]]
;
