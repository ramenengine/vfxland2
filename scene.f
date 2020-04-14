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

256 /scene array scene
64 1024 cells array tiledata  \ attribute data (64 tilesets supported)

: init-layer  16e fdup l.th! l.tw! 1e fdup l.paray! l.parax!
    0e fdup l.scrolly! l.scrollx! ;

: ?exist
    dup zcount file-exists not if cr zcount type ."  not found" 0 else 1 then
;

: load-stm ( zstr tilemap -- )
    [[ ?dup if ?exist if r/o[ 
        0 sp@ 4 read drop
        0 sp@ 2 read ( w ) dup tm.cols! cells tm.stride!
        0 sp@ 2 read ( h ) tm.rows!
        tm.base  bytes-left read
    ]file then then ]] 
;

: create-stm ( cols rows zstr -- )
    newfile[
        s" STMP" write
        over sp@ 2 write drop
        dup sp@ 2 write drop
        * cells dup allocate throw dup rot write
        free throw
    ]file
;

: load-iol ( zstr -- )
    ?dup if ?exist if r/o[
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

: clear-objects  ( -- )
    0 object  [ lenof object /objslot * ]# erase ;

: scene:  ( i - <name> ) ( - n )
    >in @ >r
    dup constant scene [[
    r> >in ! bl parse s>z s.zname!
    [ bgp1 's tm.cols 16 * ]# s>f fdup s.w! s.h!
    4 0 do i s.layer [[ init-layer ]] loop
;

: ;scene ]] ;

: iol-path  ( scene ) z" data/" z$ swap 's s.zname z+  +z" .iol" ;
: tad-path  ( layer ) 's l.zbmp zcount 4 - s>z +z" .tad" ;

: load  ( n )
    scene [[
        4 0 do i s.layer [[
            l.tw l.th i bgp [[ tm.th! tm.tw! ]]
            l.zstm @ l.zstm zcount FileExist? and if
                l.zstm i bgp load-stm
            else
                i bgp [[
                    256 tm.cols! 256 tm.rows!
                    256 cells tm.stride!
                    me clear-tilemap
                ]]
            then            
            l.zbmp @ if 
                my tad-path ?exist if
                    r/o[ 0 l.bmp# tileattrs /tileattrs read ]file
                then
            then
        ]] loop
        my iol-path ?exist if load-iol else clear-objects then
    ]]
;


: .scenes
    [ lenof scene ]# 0 do
        i scene [[ s.zname zcount ?dup if
            cr ." #" i 3 .r ."  --- " type ."  --- " 
            s.w f>s . ." x " s.h f>s .
            else drop then
        ]]
    loop cr 
;