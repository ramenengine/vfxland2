create str 1000 allot
0 value >str

: Emit-string  drop  str >str + c!  1 +to >str ;
: Type-string  drop  bounds do i c@ emit loop ;
: CR-string drop ;

create string-vectors
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' Emit-string ,
  ' drop ,
  ' Type-string ,
  ' CR-string ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,
  ' drop ,

create strdev   0 , string-vectors ,

0 value old-dev
: zstr[  0 to >str  op-handle @ to old-dev  strdev op-handle ! ;
: ]zstr  0 emit  str  old-dev op-handle ! ;