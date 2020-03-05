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
include %lib%/x86/NDP387.FTH

0 value bmp
create m 16 cells allot


0 value me
: (fgetter)  ( ofs - <name> ofs ) create dup , does> @ me + sf@ ;
: (fsetter)  ( ofs - <name> ofs ) create dup , does> @ me + sf! ;
: fgetset  (fgetter) (fsetter) cell+ ;
: (getter)  ( ofs - <name> ofs ) create dup , does> @ me + @ ;
: (setter)  ( ofs - <name> ofs ) create dup , does> @ me + ! ;
: getset  (getter) (setter) cell+ ;

0
fgetset x x!  \ x pos
fgetset y y!  \ y pos
getset si si! \ sprite index
constant /OBJECT

create objects 256 /OBJECT * allot
: object /OBJECT * objects + to me ;
0 object

: btn  kbs0 swap al_key_down ;

: ctl
    <left> btn if x -1e + x! then
    <right> btn if x 1e + x! then
    <up> btn if y -1e + y! then
    <down> btn if y 1e + y! then
;

: xy
    x y
;

: test
    0e 0e 1e 1e al_clear_to_color
    256 0 do
        i object
        bmp si 16 * s>f 0e 16e 16e xy 0 al_draw_bitmap_region
    loop
;

synonym rnd choose
: frnd  1000e f* f>s choose s>f 1000e f/ ;

:make init
    z" random.png" al_load_bitmap to bmp
    256 0 do
        i object
        320e frnd x! 240e frnd y!
        8 rnd si!
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