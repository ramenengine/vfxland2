module undoing

begin-structure /snapshot
    field: prev
    field: srcadr
    field: size
    0 +field body
end-structure

0 value last-snapshot

: snapshot  ( adr c - snapshot )
    dup /snapshot + allocate throw >r
    last-snapshot r@ prev !  r@ to last-snapshot
    2dup r@ size ! r@ srcadr !
    r> body swap move
;

: !ss   dup cell snapshot ! ;
: 2!ss  dup 2 cells snapshot 2! ;

: undo  ( - )
    last-snapshot if
        last-snapshot >r
        r@ body r@ srcadr @ r@ size @ move        
        r@ prev @ to last-snapshot
        r> free throw
    then
;

: clear-history
    last-snapshot ?dup if
        begin ?dup while >r
            r@ prev @ r> free throw
        repeat
    then
;

export undo
export snapshot
export clear-history
export !ss
export 2!ss

end-module