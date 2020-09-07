\ angles are clockwise from (1,0)

: fscale  ( f: x y s - f: x y )
    fswap fover f* frot frot f* fswap ;

: puvec  ( deg - x y )
    p>f deg>rad fdup fcos f>p fsin f>p ;  

: fuvec  ( f: deg - f: x f: y )
    deg>rad fdup fcos fswap fsin ;  

: pvec  ( deg len - x y )  
    p>f p>f fuvec frot fscale f>p f>p swap ;

: pangle  ( x y - deg )
    p>f p>f fatan2 rad>deg 360e f+ 360e fmod f>p ;
    
: phypot  ( x y - n )
    p>f fdup f* p>f fdup f* f+ fsqrt f>p ;
 
: pdist  ( x y x y - n )
    2- phypot ;   
