include allegro-5.2.3.f
1 9 lshift constant ALLEGRO_FULLSCREEN_WINDOW
0 value displayw
0 value displayh

: test
    $5020300 0 al_install_system .
    al_init_acodec_addon .
    al_init_image_addon .
    al_init_native_dialog_addon .
    al_init_primitives_addon .
    al_init_font_addon
    al_init_ttf_addon .
\    ALLEGRO_FULLSCREEN_WINDOW al_set_new_display_flags
    0 0 al_create_display
        dup al_get_display_width to displayw
            al_get_display_height to displayh
;

\ TODO:
\ [ ] essential functions
\ [ ] basic repl with game porthole
\ [ ] game mode
\ [ ] graphics system - images plus extra data ... see gfx.txt
\ [ ] save/load "project"


: .0  10000 * ;
: .n  10000 */ ;
: >i  10000 / ;
