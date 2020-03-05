include allegro-5.2.3.f
1 9 lshift constant ALLEGRO_FULLSCREEN_WINDOW
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
    
\    ALLEGRO_FULLSCREEN_WINDOW al_set_new_display_flags
\    0 0 al_create_display to display
    640 480 al_create_display to display
    display al_get_display_width to displayw
    display al_get_display_height to displayh
;
: go
    init-allegro
    init
    begin
        update
        kbs0 al_get_keyboard_state
    kbs0 59 al_key_down until
;

: .0  10000 * ;
: //  >r 10000 r> */ ;
: >i  10000 / ;

include %lib%/x86/NDP387.FTH
: 1pf  s>f 10000e f/ ;
: 2pf  swap 1pf 1pf ;
: 3pf  rot 1pf swap 1pf 1pf ;
: 4pf  >r >r 2pf r> r> 2pf ;

include roger.f

: test
    0e 0e 1e 1e al_clear_to_color
;

:make update
    test
    display al_flip_display
;

go