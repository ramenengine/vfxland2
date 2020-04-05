synonym | locals|
: ]#  ] postpone literal ;

: bmpw  al_get_bitmap_width ;
: bmph  al_get_bitmap_height ;

: tm.dims  tm.cols tm.rows ;
: tm.scroll!  tm.scrolly! tm.scrollx! ;

create zbuf  256 allot
: z$   zcount zbuf zplace  zbuf ;
: z+   swap >r zcount r@ zappend r> ;
: s>z  zbuf zplace  zbuf ;

also system
: +z"  
  [char] " parse >SyspadZ z+
;
ndcs: ( -- )
  postpone (z")  [char] " parse z$,  postpone z+ 
  discard-sinline  ;
previous

synonym file-exists fileExist? 

: 2s>f  swap s>f s>f ;

synonym my me
