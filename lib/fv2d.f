\ angles are clockwise from (1,0)

: fscale  ( f: x y s - f: x y )
    fswap fover f* frot frot f* fswap ;

: fuvec  ( f: deg - f: x y )
    deg>rad fdup fcos fswap fsin ;  

: fvec  ( f: deg len - f: x y )  
    fswap fuvec frot fscale ;

: fangle  ( f: x y - f: deg )
    fswap fatan2 rad>deg 360e f+ 360e fmod ;
    
: fhypot  ( f: x y - f: n )
    fdup f* fswap fdup f* f+ fsqrt ;
 
: 2f+  frot f+ frot frot f+ fswap ;
: 2f-  frot fswap f-  frot frot f- fswap ;

: fdist  ( f: x y x y - f: n )
    2f- fhypot ;   
