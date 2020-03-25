finit
[defined] shutdown [if] shutdown [then]
[undefined] max-objects [if] 256 constant max-objects [then]
[undefined] /objslot    [if] 256 constant /objslot [then] 

\ ------------------------------------------------------------------------

include allegro-5.2.3.f
require lib/fclean.f
: require  get-order depth fclean -order require depth <
    abort" Stack item(s) left behind" set-order ;

320 value vieww
240 value viewh
0 value displayw
0 value displayh
0 value display
0 value monitorw
create kbs0 /ALLEGRO_KEYBOARD_STATE allot&erase
create kbs1 /ALLEGRO_KEYBOARD_STATE allot&erase
create ms0 /ALLEGRO_MOUSE_STATE allot&erase
create ms1 /ALLEGRO_MOUSE_STATE allot&erase
0 value mixer
0 value voice
create mi /ALLEGRO_MONITOR_INFO allot&erase
0 value queue
create alevt 256 allot&erase
0 value bif  \ builtin font

defer load-data ' noop is load-data
defer init-game ' noop is init-game
defer deinit    ' noop is deinit
defer system    ' noop is system


0 value scr

: execute  ?dup if execute then ;
: screen-hook  create dup , cell+ does> @ scr + @ execute ;

0
screen-hook update    
screen-hook pump      
screen-hook step
screen-hook resume
screen-hook object
constant /screen

: screen  create /screen allot&erase
    does>
        to scr
        resume
;

: :hook   ( - <screen> <hook> code; )
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
    $5020300 0 al_install_system check
    
    al_init_image_addon check
    al_init_native_dialog_addon check
    al_init_primitives_addon check
    al_init_font_addon
    al_init_ttf_addon check
    al_init_acodec_addon check
    al_install_audio 0= abort" Error installing audio."
    al_install_haptic check
    al_install_joystick check
    al_install_keyboard check
    al_install_mouse check
    al_install_touch_input check
    ALLEGRO_VSYNC 1 0 al_set_new_display_option
\    ALLEGRO_FULLSCREEN_WINDOW al_set_new_display_flags
\    ALLEGRO_FULLSCREEN al_set_new_display_flags
\    0 0 al_create_display to display
    640 480 al_create_display to display
    display al_get_display_width to displayw
    display al_get_display_height to displayh
    \ 0 mi al_get_monitor_info drop
    \ mi cell+ cell+ @ to monitorw
    \ 1920 to monitorw
    \ display monitorw displayw - 0 al_set_window_position
    display 0 0 al_set_window_position
    0 to mixer  0 to voice
    64 al_reserve_samples 0= abort" Allegro: Error reserving samples." 
    +audio
    al_create_event_queue to queue
    queue  display       al_get_display_event_source  al_register_event_source
    queue                al_get_mouse_event_source    al_register_event_source
    queue                al_get_keyboard_event_source al_register_event_source
    al_create_builtin_font to bif
;
: go
    begin
        update
        display al_flip_display
        pause
        kbs0 kbs1 /ALLEGRO_KEYBOARD_STATE move
        kbs0 al_get_keyboard_state
        ms0 ms1 /ALLEGRO_MOUSE_STATE move
        ms0 al_get_mouse_state
        system
        begin queue alevt al_get_next_event while pump repeat
        step
    kbs0 59 al_key_down until
;
: init
    init-allegro
    load-data
    init-game
;
: warm
    init
    go
;
: shutdown
    deinit
    al_uninstall_system
;
: cold
    warm
    shutdown
;

: etype  ( - ALLEGRO_EVENT_TYPE )  alevt ALLEGRO_EVENT.type @ ;
: keycode  alevt KEYBOARD_EVENT.keycode @ ;
: unichar  alevt KEYBOARD_EVENT.unichar @ ;

\ --------------------------------------------------------------

synonym rnd choose
: frnd  1000e f* f>s choose s>f 1000e f/ ;
: :make  :noname  postpone [  [compile] is  ] ;
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
    >r  r@ >tos @
    r@ @ 1 - r@ (wrap) r> ! ;
: push  ( val stack - )
    >r  r@ @ 1 + r@ (wrap) r@ !
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
: buffer  create over , + does> @ me + ;


16 stack objstack
: {{  me objstack push to me ;
: }}  objstack pop to me ;
: as  to me ;
: 's
    state @ if  s" me >r to me" evaluate bl parse evaluate s" r> to me" evaluate
    exit then   s" {{" evaluate bl parse evaluate s" }}" evaluate ; immediate
    
    
\ --------------------------------------------------------------

0
    fgetset x x!  \ x pos
    fgetset y y!  \ y pos
    getset ix ix!
    getset iy iy! 
    getset attr attr! \ attributes ---- ---- ---- --VH ---- hhhh ---w wwww
    getset en en!
    getset bmp# bmp#!
constant /OBJECT

: xy  x y ;
: xy!  y! x! ;
: iw  attr $1f and 1 + 4 lshift s>f ;
: ih  attr $f00 and 8 rshift 1 + 4 lshift s>f ;
: flip  attr $3000 and 12 rshift ;
: flip! 12 lshift attr [ $3000 invert ]# and or attr! ;
: init-object  0e 0e xy!  1 en! ;

max-objects /objslot array (object)
screen game game
:hook game object (object) ;
0 object to me

: btn  kbs0 swap al_key_down ;

128 cell array bitmap
: bmp  bitmap @ ;
: bmp! bitmap ! ;

: ?LOADBMP  ( var zstr )
    dup zcount FileExist? if
        over @ ?dup if al_destroy_bitmap then
        al_load_bitmap swap !
    else drop drop then
;

: ?LOADSMP  ( var zstr )
    dup zcount FileExist? if
        over @ ?dup if al_destroy_sample then
        al_load_sample swap !
    else drop drop then
;

256 cell array sample

: -bitmap  ?dup if al_destroy_bitmap then ;
: -sample  ?dup if al_destroy_sample then ;

: destroy-bitmaps
    [ lenof bitmap ]# 0 do i bitmap @ -bitmap loop
;

: destroy-samples
    [ lenof sample ]# 0 do i sample @ -sample loop
;

:make deinit
    destroy-bitmaps
    destroy-samples
;

: load-bitmap  ( n zpath - ) swap bitmap swap ?loadbmp ;
: load-sample  ( n zpath - ) swap sample swap ?loadsmp ;

0 value sid
0 value strm

: play  ( sample loopmode - )
    >r  1e 0e 1e  r>  & sid  al_play_sample ;

: stream ( zstr loopmode - )
    strm ?dup if al_destroy_audio_stream  0 to strm then
    >r
    3 2048  al_load_audio_stream
        dup 0 = abort" Failed to stream audio file."
        to strm 
    strm r> al_set_audio_stream_playmode drop
    strm mixer al_attach_audio_stream_to_mixer drop
;

defer bg          ' noop is bg
defer fg          ' noop is fg
defer hud         ' noop is hud

0e fvalue fgr  0e fvalue fgg  0e fvalue fgb  1e fvalue fga
0e fvalue bgr  0e fvalue bgg  1e fvalue bgb 

: color  ( f: r g b )  to fgb to fgg to fgr ;
: alpha  ( f: a )  to fga ;
: backdrop  fgb to bgb fgg to bgg bgr to bgr ;

2e fvalue zoom
: matrix  create 16 cells allot ;
matrix m

: draw-as-sprite  ( bitmap# - )
    bmp ?dup if ix s>f iy s>f iw ih x floor y floor flip al_draw_bitmap_region then
;

: draw-sprites ( - )
    1 al_hold_bitmap_drawing
    max-objects 0 do
        i object to me
        en if bmp# draw-as-sprite then
    loop
    0 al_hold_bitmap_drawing
;

:make fg
    draw-sprites
;

: 2x
    m al_identity_transform
    m zoom zoom al_scale_transform
    m al_use_transform
;

: cls 
    bgr bgg bgb 1e al_clear_to_color
;

:hook game update
    me >r
        2x cls bg fg hud
    r> to me
;

( -------------------------------------------------------------- )


( -------------------------------------------------------------- )

( tile format: 000000vh 00000000 yyyyyyy xxxxxxx )
( y and x are multiplied by the plane's tile dimensions )
( -1 or $FFFFFFFF means transparent, i.e. a blank space )

/OBJECT
    fgetset tm.w tm.w!
    fgetset tm.h tm.h!
    getset tm.rows tm.rows!
    getset tm.cols tm.cols!
    getset tm.bmp# tm.bmp#!       \ index
    getset tm.stride tm.stride!
    getset tm.base tm.base!     \ address
    fgetset tm.tw tm.tw!
    fgetset tm.th tm.th!
    fgetset tm.scrollx tm.scrollx!
    fgetset tm.scrolly tm.scrolly!
constant /TILEMAP

: plane:  ( w h - <name> )  \ w and h in tiles and defines the buffer size
    create here {{ /tilemap /allot
    init-object
    2dup tm.cols! tm.rows!
    2dup * cells allotment tm.base!
    over cells tm.stride!
    16e tm.tw! 16e tm.th!
    s>f tm.th f* viewh s>f fmin tm.h!
    s>f tm.tw f* vieww s>f fmin tm.w!    
;

: ;plane  }} ;
 
0e fvalue ox
0e fvalue oy
0e fvalue rx

: tm-vrows  tm.h tm.th f/ f>s 1 + ;
: tm-vcols  tm.w tm.tw f/ f>s 1 + ;

: draw-as-tilemap  ( - )
    tm.bmp# bmp
    0 locals| t b |
    b 0 = if exit then
    tm.base 0 = if exit then
    \ b al_get_bitmap_width tm.tw f>s / to tcols
    
    1 al_hold_bitmap_drawing
    x zoom f* f>s y zoom f* f>s
        tm.w zoom f* f>s tm.h zoom f* f>s
        al_set_clipping_rectangle
    x to ox y to oy
    x tm.scrollx tm.tw fmod f- x!
    y tm.scrolly tm.th fmod f- y!
    x to rx
    
    tm.base
        tm.scrollx tm.tw f/ f>s cells +
        tm.scrolly tm.th f/ f>s tm.stride * +
        
        ( adr )
        tm-vrows 0 do
            dup tm-vcols cells bounds do
                i @ -1 <> if
                    b   i @ $ff and s>f tm.tw f*
                        i @ $ff00 and 8 rshift s>f tm.th f*
                        tm.tw tm.th xy i @ 24 rshift al_draw_bitmap_region                    
                then
                x tm.tw f+ x!
            cell +loop
            tm.stride +
            rx x!
            y tm.th f+ y!
        loop
        drop
    
    ox x! oy y!
    0 al_hold_bitmap_drawing
    al_reset_clipping_rectangle
;

: pack-tile  ( x y flip - )  24 lshift swap 8 lshift or or ;

0e fvalue dx
0e fvalue dy

: draw-tile ( tile plane f: x y - )
    to dy to dx
    {{ locals| t |
        tm.bmp# bmp ?dup if 
            t $ff and s>f tm.tw f*
            t $ff00 and 8 rshift s>f tm.th f*
            tm.tw tm.th dx dy t 24 rshift al_draw_bitmap_region
        then
    }}
;

