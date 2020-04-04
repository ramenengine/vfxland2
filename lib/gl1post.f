: shutdown
    deinit
    al_uninstall_system
;
: empty  shutdown empty ;
: go
    begin
        me >r update r> to me
        display al_flip_display
        pause
        kbs0 kbs1 /ALLEGRO_KEYBOARD_STATE move
        kbs0 al_get_keyboard_state
        ms0 ms1 /ALLEGRO_MOUSE_STATE move
        ms0 al_get_mouse_state
        system
        begin queue alevt al_get_next_event while pump repeat
        me >r step r> to me
    kbs0 59 al_key_down until
    [defined] fullscreen [if] shutdown bye [then]
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
: cold
    warm
    shutdown
;