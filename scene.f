require lib/filelib.f
require utils.f
require lib/a.f

256 256 plane: lyr1 1 tm.bmp#! ;plane
256 256 plane: lyr2 1 tm.bmp#! ;plane
256 256 plane: lyr3 1 tm.bmp#! ;plane
256 256 plane: lyr4 1 tm.bmp#! ;plane

1024 cells constant /tileattrs 

create tiledata /tileattrs lenof bitmap * /allot
: tileattrs  ( n bmp# - a ) 1024 * + cells tiledata + ;
\ keep the data struct abstracted away so we can add stuff (use other arrays)
: tileflags  ( n bmp# - n ) tileattrs @ ;
: tileflags! ( n n bmp# ) tileattrs ! ;


4 cell array layer
    lyr1 0 layer !
    lyr2 1 layer !
    lyr3 2 layer !
    lyr4 3 layer ! 

: lyr  layer @ ;

\ internal layer struct
/TILEMAP
    64 zgetset l.zstm l.zstm!  \ tilemap path
    64 zgetset l.zbmp l.zbmp!  \ tile bitmap path
    fgetset l.parax l.parax!
    fgetset l.paray l.paray!
constant /LAYER

\ internal scene struct
0
    32 zgetset s.zname s.zname!
    fgetset s.w s.w!      \ bounds
    fgetset s.h s.h!
    4 /layer field[] s.layer
constant /SCENE

/scene 200 array scene
lenof bitmap 4096 cells array tiledata  \ attribute data


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
        0 object [ lenof object ]# /objslot * write
    ]file 
;

: clear-tilemap  ( tilemap -- )
    [[ tm.base  tm.dims * cells  erase  ]] ;

: scene:  ( i - <name> ) ( - n )
    >in @ >r
    dup constant scene [[
    r> >in ! bl parse s>z s.zname!
    4 0 do i s.layer [[ init-tilemap ]] loop
;

: ;scene ]] ;

: iol-path  ( scene ) z" data/" z$ swap 's s.zname z+  +z" .iol" ;
: tad-path  ( layer ) 's l.zbmp zcount 4 - s>z +z" .tad" ;

: load  ( n )
    scene [[
        4 0 do i s.layer [[            
            l.zstm @ if
                l.zstm i lyr load-stm
                l.zbmp @ if 
                    my tad-path ?exist if file[ 0 tm.bmp# tileattrs /tileattrs read ]file then
                then
            else i lyr clear-tilemap
            then            
        ]] loop
        my iol-path ?exist if load-iol then
    ]]
;

