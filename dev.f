include counter

lenof bitmap 256 array zbmp-file
lenof bitmap cell array bmp-mtime

: as-to expose-module ;

: mtime@
    al_create_fs_entry >r
    r@ al_get_fs_entry_mtime 
    r> al_destroy_fs_entry 
;

( extend load-bitmap to record the path and time modified )
: load-bitmap  ( i zstr - )
    2dup
    2dup load-bitmap
    zcount rot zbmp-file swap 1 + move
    ( i zstr ) mtime@ swap bmp-mtime !
;
