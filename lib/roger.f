variable bud

: sfrand randseed @  3141592621 *  1+  DUP randseed ! ;
  also system  assign sfrand to-do RANDOM  previous

synonym rnd choose

: ]#  ] postpone literal ;
synonym | locals| immediate
synonym /allot allot&erase
: allotment  here >r /allot r> ;
synonym gild freeze
synonym & addr immediate


: .cell  
  base @ hex  swap
  ." $" 0 <# # # # # # # # # #> type
  base !
;
    
: .s            
  cr  depth ?dup if
    dup 0< #-4 ?throw
    0 do
      i pick  .cell space
    loop
  else
    ." empty stack"
  then
;

: 2-  rot swap - >r - r> ;
