\ notes

\  how to bring a window into focus?

include %lib%/x86/hfp387.FTH
include Extern.fth
include allegro-5.2.3.f
1 9 lshift constant ALLEGRO_FULLSCREEN_WINDOW
26 constant ALLEGRO_VSYNC
0 value displayw
0 value displayh
0 value display
create kbs0 /ALLEGRO_KEYBOARD_STATE allot

\ ?
defer init    ' noop is init
defer update  ' noop is update

: init-allegro
    $5020300 0 al_install_system .
    
    al_init_acodec_addon .
    al_init_image_addon .
    al_init_native_dialog_addon .
    al_init_primitives_addon .
    al_init_font_addon
    al_init_ttf_addon .
    al_install_audio .
    al_install_haptic .
    al_install_joystick .
    al_install_keyboard .
    al_install_mouse .
    al_install_touch_input .
    ALLEGRO_VSYNC 1 0 al_set_new_display_option
\    ALLEGRO_FULLSCREEN_WINDOW al_set_new_display_flags
\    0 0 al_create_display to display
    640 480 al_create_display to display
    display al_get_display_width to displayw
    display al_get_display_height to displayh
;
: go
    begin
        update
        kbs0 al_get_keyboard_state
    kbs0 59 al_key_down until
;
: cold
    init-allegro
    init
    go
;

\ ------------------------------------------------------------

include roger.f
include keys.f

synonym rnd choose
: frnd  1000e f* f>s choose s>f 1000e f/ ;

0 value bmp
create m 16 cells allot
create tilemap 256 256 cells * allot

0e fvalue x
0e fvalue y

: tile  ( n - )
    bmp swap 16 * s>f 0e 16e 16e x y 0 al_draw_bitmap_region
;

0e fvalue ox
0e fvalue oy

: background
    x to ox y to oy
    tilemap ( adr )
    16 0 do
        dup
        21 0 do
            dup @ tile cell+ 
            16e +to x
        loop
        drop 256 cells +
        ox to x
        16e +to y
    loop
    drop oy to y ox to x
;

: btn  kbs0 swap al_key_down ;

: ctl
    <left> btn if -1e +to x then
    <right> btn if 1e +to x then
    <up> btn if -1e +to y then
    <down> btn if 1e +to y then
;

: test
    0e 0e 1e 1e al_clear_to_color
    background
    ctl
;

:make init
    z" random.png" al_load_bitmap to bmp
    256 256 * 0 do
        8 rnd i cells tilemap + !
    loop
;

:make update
    m al_identity_transform
    m 2e 2e al_scale_transform
    m al_use_transform
    test
    display al_flip_display
;

cold