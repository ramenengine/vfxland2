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