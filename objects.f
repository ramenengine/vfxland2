256 constant max-objdescs

/OBJECT
    getset objtype objtype!
    getset action# action#!
drop


max-objdescs /objslot array objdesc

: objdesc: ( n - <name> ) ( - n )
    dup constant dup objdesc {{
    objtype !
;

: ;objdesc }} ;


max-objdescs 256 cells array sdata  \ static data

: (vector!) create dup , does> @ objtype sdata + ! ;
: (vector) create dup , does> @ objtype sdata + @ execute ;
: vector  (vector) (vector!) cell+ ;
: ::  ( objtype - <vector> )
    {{ :noname ' >body @ objtype sdata + ! }} ;


( TODO: actions )

0
    vector start start!
    vector think think!   \ temporary
value /sdata



0 include lemming.f