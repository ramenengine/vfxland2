finit
[undefined] max-objects [if] 256 constant max-objects [then]
[undefined] /objslot    [if] 256 constant /objslot [then] 

\ ------------------------------------------------------------------------

0 value dev
0 value fullscreen
0 value mswin
0 value export?

:noname
    CommandLine 2drop
    argc 1 ?do
        i argv[ zcount 
            2dup s" -dev" compare 0= dev or to dev 
            2dup s" -fullscreen" compare 0= fullscreen or to fullscreen 
            2dup s" -mswin" compare 0= mswin or to mswin
            2dup s" -export" compare 0= export? or to export?
        2drop 
    loop
; execute

\ ------------------------------------------------------------------------

dev [if]
    synonym turnkey SaveConsole
[else]
    synonym turnkey save
[then]

\ ------------------------------------------------------------------------

include allegro-5.2.5.f
: require  get-order depth >R require depth R> >
    abort"  Stack item(s) left behind" set-order ;



( ~~ Fixed Point ~~ )
: p   16 lshift ;           \ $IIIIFFFF
: /p  $00010000 -rot */ ;
: p*  $00010000 */ ;
: p/  $00010000 swap */ ;
: p>f s>f  65536e f/ ;
: f>p 65536e f* f>s ;
: p.  p>f  f. ;
: p>s 16 arshift ;
: %   100 /p ;
: pvalue  value ;
: pconstant  constant ;
: pround  p>f fround f>p ;


320 value vieww
240 value viewh
0 value display
create kbs0 /ALLEGRO_KEYBOARD_STATE allot&erase
create kbs1 /ALLEGRO_KEYBOARD_STATE allot&erase
create ms0 /ALLEGRO_MOUSE_STATE allot&erase
create ms1 /ALLEGRO_MOUSE_STATE allot&erase
create ms2 /ALLEGRO_MOUSE_STATE allot&erase
0 value mixer
0 value voice
create mi /ALLEGRO_MONITOR_INFO allot&erase
0 value queue
create alevt 256 allot&erase
0 value bif  \ builtin font
0 value mousex
0 value mousey
0 value mwheelx
0 value mwheely

: load-data ;
: init-game ;
: system    ;

0 value scr

: execute  ?dup if execute then ;
: screen-hook  create dup , cell+ does> @ scr + @ execute ;
: does-screen-get  does> @ scr + @ ;
: screen-getset   create dup , does-screen-get create dup , cell+ does> @ scr + ! ;

0
    screen-hook update    
    screen-hook pump      
    screen-hook step
    screen-hook resume
value /screen

: screen  create /screen allot&erase
    does>
        to scr
        resume
;

: :while   ( - <screen> <hook> code; )
    :noname ' >body ' >body @ + ! ;

: -audio
    mixer 0= if exit then
    mixer 0 al_set_mixer_playing drop 
;

: +audio
    mixer if  mixer #1 al_set_mixer_playing drop  exit then 
    #44100 ALLEGRO_AUDIO_DEPTH_INT16 ALLEGRO_CHANNEL_CONF_2 al_create_voice to voice
    #44100 ALLEGRO_AUDIO_DEPTH_FLOAT32 ALLEGRO_CHANNEL_CONF_2 al_create_mixer to mixer
    mixer voice al_attach_mixer_to_voice 0= abort" Couldn't initialize audio"
    mixer al_set_default_mixer drop
    mixer #1 al_set_mixer_playing drop
;

: check  0= abort" Allegro init error" ;

: init-allegro
    ALLEGRO_VERSION 0 al_install_system check
    
    al_init_image_addon check
    al_init_native_dialog_addon check
    al_init_primitives_addon check
    al_init_font_addon
    al_init_ttf_addon check
    al_init_acodec_addon check
    al_install_audio 0= abort" Error installing audio."
    al_install_haptic check
    al_install_joystick check
    al_install_mouse check
    al_install_touch_input check
    ALLEGRO_VSYNC 1 2 al_set_new_display_option
    ALLEGRO_SINGLE_BUFFER 1 2 al_set_new_display_option     \ gets us one less
                                                            \ frame of input lag
    
    [ fullscreen ] [if]
        \ ALLEGRO_FULLSCREEN_WINDOW al_set_new_display_flags
        \ 0 0 al_create_display to display
        ALLEGRO_FULLSCREEN al_set_new_display_flags
        640 480 al_create_display to display
    [else]
        640 480 al_create_display to display
        display 0 0 al_set_window_position
    [then]
    0 to mixer  0 to voice
    64 al_reserve_samples 0= abort" Allegro: Error reserving samples." 
    +audio
    al_create_event_queue to queue
    queue  display       al_get_display_event_source  al_register_event_source
    queue                al_get_mouse_event_source    al_register_event_source
    al_create_builtin_font to bif

    ALLEGRO_ADD ALLEGRO_ALPHA ALLEGRO_INVERSE_ALPHA al_set_blender
;

( -------------------------------------------------------------- )

: etype  ( - ALLEGRO_EVENT_TYPE )  alevt ALLEGRO_EVENT.type @ ;
: keycode  alevt KEYBOARD_EVENT.keycode @ ;
: unichar  alevt KEYBOARD_EVENT.unichar @ ;

\ --------------------------------------------------------------

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

( --== circular stack ==-- )
( expects length to be power of 2 )
: stack  ( length - <name> ) create 0 , dup 1 - ,  cells /allot ;
: (wrap)  cell+ @ and ;
: >tos  dup @ cells swap cell+ cell+ + ;
: >nos  dup @ 1 - over (wrap) cells swap cell+ cell+ + ;
: pop  ( stack - val )
    dup >r >tos @
    r@ @ 1 - r@ (wrap) r> ! ;
: push  ( val stack - )
    dup >r  @ 1 + r@ (wrap) r@ !
    r> >tos ! ;
: pushes  ( ... stack n - ) swap | s |  0 ?do  s push  loop ;
: pops    ( stack n - ... ) swap | s |  0 ?do  s pop  loop ;
: lenof  ' >body cell+ @ 1 + ;
: array  ( #items itemsize ) create dup , over 1 - , * /allot
         ( i - adr ) does> >r r@ (wrap) r@ @ * r> cell+ cell+ + ;


0 value me
: (fgetter)  ( ofs - <name> ofs ) create dup , does> @ me + sf@ ;
: (fsetter)  ( ofs - <name> ofs ) create dup , does> @ me + sf! ;
: fgetset  (fgetter) (fsetter) cell+ ;
: (getter)  ( ofs - <name> ofs ) create dup , does> @ me + @ ;
: (setter)  ( ofs - <name> ofs ) create dup , does> @ me + ! ;
: getset  (getter) (setter) cell+ ;
: pgetset  getset ;
: field    create over , + does> @ me + ;
: pfield   field ;
: third  2 pick ;
: field[]  ( ofs n size - <name> ofs ) create third , dup , * +
                                        does> 2@ swap ( n ofs size ) rot * + me + ;
: pfield[]  field[] ;
: (zgetter)  ( ofs size - <name> ofs size ) create over , does> @ me + ;
: (zsetter)  ( ofs size - <name> ofs size ) create over , does> @ me + zmove ;
: zgetset  (zgetter) (zsetter) + ;

16 stack objstack
: [[  me objstack push to me ;
: ]]  objstack pop to me ;
: as  to me ;
: 's
    state @ if  s" me >r to me" evaluate bl parse evaluate s" r> to me" evaluate exit then   
    s" [[" evaluate bl parse evaluate s" ]]" evaluate ; immediate
    
    
\ --------------------------------------------------------------

0
    pgetset x x!  \ x pos
    pgetset y y!  \ y pos
    getset ix ix!
    getset iy iy! 
    getset attr attr! \ attributes ---- ---- ---- --VH ---- hhhh ---w wwww
    getset en en!
    getset bmp# bmp#!
    getset id id!
value /OBJECT

: xy  x y ;
: xy!  y! x! ;
: iw  attr $1f and 1 + 4 lshift ;
: ih  attr $f00 and 8 rshift 1 + 4 lshift ;
: flip  attr $3000 and 12 rshift ;
: flip! 12 lshift attr [ $3000 invert ]# and or attr! ;
: init-object  0 0 xy!  1 en! ;

max-objects /objslot array object
screen game game
0 object to me

: object>i  0 object - /objslot / ;

: btn  kbs0 swap al_key_down ;

128 cell array bitmap
: bmp  bitmap @ ;
: bmp! bitmap ! ;

: ?LOADBMP  ( var zstr )
    dup 0= if swap ! exit then
    dup zcount FileExist? if        
        over @ ?dup if al_destroy_bitmap then
        cr dup zcount type
        al_load_bitmap swap !
    else drop drop then
;

: ?LOADSMP  ( var zstr )
    dup 0= if swap ! exit then
    dup zcount FileExist? if
        over @ ?dup if al_destroy_sample then
        cr dup zcount type
        al_load_sample swap !
    else drop drop then
;

256 cell array sample
: smp  sample @ ;

: -bitmap  ?dup if al_destroy_bitmap then ;
: -sample  ?dup if al_destroy_sample then ;

: destroy-bitmaps
    [ lenof bitmap ]# 0 do i bitmap @ -bitmap loop
;

: destroy-samples
    [ lenof sample ]# 0 do i sample @ -sample loop
;

: deinit
    destroy-bitmaps
    destroy-samples
;

: load-bitmap  ( n zpath - ) swap bitmap swap ?loadbmp ;
: load-sample  ( n zpath - ) swap sample swap ?loadsmp ;

0 value sid
0 value strm

: play  ( sample# - )
    smp  1e 0e 1e  ALLEGRO_PLAYMODE_ONCE   & sid  al_play_sample ;

: playloop  ( sample# - )
    smp  1e 0e 1e  ALLEGRO_PLAYMODE_LOOP   & sid  al_play_sample ;

: stream ( zstr loopmode - )
    strm ?dup if al_destroy_audio_stream  0 to strm then
    over 0= if 2drop exit then
    >r
    3 2048  al_load_audio_stream
        dup 0 = abort" Failed to stream audio file."
        to strm 
    strm r> al_set_audio_stream_playmode drop
    strm mixer al_attach_audio_stream_to_mixer drop
;

: streamloop  ALLEGRO_PLAYMODE_LOOP stream ;

0e fvalue fgr  0e fvalue fgg  0e fvalue fgb  1e fvalue fga
: fcolor  ( f: r g b )  to fgb to fgg to fgr ;
: falpha  ( f: a )  to fga ;

2 p value zoom

: matrix  create 16 cells allot ;
matrix m

: draw-as-sprite  ( bitmap# - )
    bmp ?dup if
        ix s>f iy s>f iw s>f ih s>f
        x p>f floor y p>f floor flip al_draw_bitmap_region
    then
;

: draw-sprites ( - )
    1 al_hold_bitmap_drawing
    max-objects 0 do
        i object as
        en if bmp# draw-as-sprite then
    loop
    0 al_hold_bitmap_drawing
;


: 2x
    2 p to zoom
    m al_identity_transform
    m zoom p>f fdup al_scale_transform
    m al_use_transform
;

: cls 
    fgr fgg fgb 1e al_clear_to_color
;

( -------------------------------------------------------------- )

( tile format: 000000vh 00000000 nnnnnnnn nnnnnnnn )
( -1 or $FFFFFFFF means transparent, i.e. a blank space )

/OBJECT
    getset tm.w tm.w!              \ display box in pixels 
    getset tm.h tm.h!
    getset tm.rows tm.rows!         \ total rows and cols in tiles
    getset tm.cols tm.cols!
    getset tm.bmp# tm.bmp#!         \ bitmap index
    getset tm.stride tm.stride!     \ row stride in bytes
    getset tm.base tm.base!         \ address
    getset tm.tw tm.tw!            \ tile size
    getset tm.th tm.th!
    getset tm.scrollx tm.scrollx!  \ scroll coords in pixels
    getset tm.scrolly tm.scrolly!
constant /TILEMAP

: init-tilemap
    init-object    
    16 tm.tw! 16 tm.th!            \ default tile size
    vieww tm.w! viewh tm.h!        \ default dimensions
;

: plane:  ( w h - <name> )  \ w and h in tiles and defines the buffer size
    create here [[ /tilemap /allot
    init-tilemap
    2dup tm.cols! tm.rows!
    2dup * cells allotment tm.base!
    drop cells tm.stride!
    tm.h viewh min tm.h!
    tm.w vieww min tm.w!    
;

: ;plane  ]] ;
 

0 value rx  \ row x
0 value tcols
0 value dx
0 value dy

: tm-vrows  tm.h tm.th / 1 + ;
: tm-vcols  tm.w tm.tw / 1 + ;

: draw-as-tilemap  ( - )
    tm.bmp# bmp
    0 locals| t b |
    b 0 = if exit then
    tm.base 0 = if exit then
    b al_get_bitmap_width tm.tw / to tcols
    
    1 al_hold_bitmap_drawing
    
    x p>s to dx  y p>s to dy
    
    dx zoom p* dy zoom p* 
    tm.w zoom p* tm.h zoom p* 
        al_set_clipping_rectangle
               
    dx tm.scrollx tm.tw mod - to dx
    dy tm.scrolly tm.th mod - to dy
    dx to rx
    
    tm.base
        tm.scrollx tm.tw / cells +
        tm.scrolly tm.th / tm.stride * +
        
        ( adr )
        tm-vrows 0 do
            dup tm-vcols cells bounds do
                i @ -1 <> if
                    b   i @ $ffff and tcols /mod swap tm.tw * s>f  tm.th * s>f 
                        tm.tw s>f tm.th s>f
                        dx s>f dy s>f i @ 24 rshift al_draw_bitmap_region
                then
                tm.tw +to dx
            cell +loop
            tm.stride +
            rx to dx
            tm.th +to dy
        loop
        drop
    
    0 al_hold_bitmap_drawing
    al_reset_clipping_rectangle
;

: pack-tile  ( n flip - )  24 lshift or ;



: draw-tile ( tile plane x y - )
    to dy to dx
    [[ locals| t |
        tm.bmp# bmp ?dup if
            tm.bmp# bmp al_get_bitmap_width tm.tw / to tcols
            t $ffff and tcols /mod swap tm.tw * s>f  tm.th * s>f 
            tm.tw s>f  tm.th s>f  dx s>f  dy s>f  t 24 rshift al_draw_bitmap_region
        then
    ]]
;

: find-tile ( col row tilemap -- adr )
    [[ tm.stride * swap cells + tm.base + ]] ;

\ ---------------------------------------------------------------

:while game update
    2x 0e 0e 0e 1e fcolor cls draw-sprites
;

\ ---------------------------------------------------------------
dev [if]
    mswin [if] include counter [then]
    
    mswin [if]
        extern void * GetForegroundWindow( );
        extern bool SetForegroundWindow( void * hwnd );
        
        GetForegroundWindow constant vfx-hwnd
    [then]
    
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
[then]

