require keys.f
require lib/filelib.f

synonym | locals|
: ]#  ] postpone literal ;

:make load-data
    1 z" data/tileset.png" load-bitmap
;

edplane value tm

: tm>dims  {{ tm.w tm.tw f/ f>s tm.h tm.th f/ f>s }} ;

\ : randomize
\     data a!
\     tm tm>dims * 0 do 8 rnd 8 rnd 0 packtile !+ loop
\ ;
\ randomize

256 256 plane plane1
: data  plane1 {{ tm.base }} ;

: new-scene  { zstr -- }
    0 zstr newfile[
        data plane1 tm>dims * cells write
        [ lenof object ]# 0 do i object /object-slot write loop
    ]file
;

: load-scene  { zstr -- }
    zstr zcount fileExist? not if  zstr new-scene  then
    zstr file[
        data plane1 tm>dims * cells read
        [ lenof object ]# 0 do i object /object-slot read loop        
    ]
;

struct /scene
    256 +field s.zpath
end-struct

/scene 100 array scene

: scene:  ( i - <name> <path> )
    dup constant
    bl parse rot scene s.zpath zplace
;

: load  ( n ) scene s.zpath load-scene ;

