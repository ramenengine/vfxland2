extern bool QueryPerformanceCounter( void * count );
extern bool QueryPerformanceFrequency( void * lpFrequency );

: DCOUNTER ( -- d )   0 0 SP@ QueryPerformanceCounter DROP SWAP ;

: uCOUNTER ( -- d )
   DCOUNTER  1000000 0 0 SP@ QueryPerformanceFrequency DROP NIP M*/  ;

: COUNTER ( -- ms )
   DCOUNTER  1000 0 0 SP@ QueryPerformanceFrequency DROP NIP M*/ DROP  ;

: time?  ( xt - )
   >r ucounter r> execute ucounter 2swap d- d. ;