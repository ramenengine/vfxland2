256 constant max-prefabs

/OBJECT
    getset objtype objtype!
to /OBJECT

/objslot 128 - constant /userfields

max-prefabs /objslot array prefab
max-prefabs 1024 array sdata  \ static data such as actions

: lastword  last @ ctrl>nfa count ;

: prefab: ( n - <name> ) ( - n )
    dup constant dup prefab [[
    dup >r lastword r> sdata place
    dup objtype!
        16 * s>f fdup xy!  \ default positioning; can be changed using the prefabs.iol file
    true en!
;

: ;prefab ]] ;

: ext: /userfields ;
: ;ext ;

32  \ name (1+31)
value /sdata

: (method!) create /sdata , does> @ objtype sdata + ! ;
: (method) create /sdata  , does> @ objtype sdata + @ execute ;
: method  (method) (method!) cell +to /sdata ;
: ::  ( prefab - <name> )
    prefab [[ :noname ' >body @ objtype sdata + ! ]] ;

method start start!
method think think!

: become  ( n ) >r
    x y
    r> prefab me /objslot move
    y! x! ;

: script  ( n - <name> )
    dup prefab 's en abort" Prefab # already taken"
    false to warnings?
    include
    true to warnings?
;

create temp$ 256 allot

: hone  ( - <name> ) me >r
    false to warnings?
    >in @ ' >body @ swap >in !
    s" scripts/" temp$ place  bl parse temp$ append  temp$ count GetPathSpec included
    true to warnings?
    r> as
;  

: load-prefabs
    z" prefabs.iol" ?dup if ?exist if
        r/o[ 0 prefab [ lenof prefab /objslot * ]# read ]file
    then then
    s" scripts.f" included
;

: like:  ( - <name> )
    objtype >r
    ' >body @ dup become
    r> objtype!
    ( old ) sdata 32 + objtype sdata 32 + /sdata 32 - move  ( preserve name )
;