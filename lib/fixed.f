
( ~~ Fixed Point ~~ )
: p   16 lshift ;           \ $IIIIFFFF
: p*  $00010000 */ ;
: p/  $00010000 swap */ ;
: p>f s>f  65536e f/ ;
: f>p 65536e f* f>s ;
: p.  p>f  f. ;
: p>s 16 arshift ;
: pvalue  value ;
: pconstant  constant ;
: pround  p>f fround f>p ;
: pfloor  $ffff0000 and ;