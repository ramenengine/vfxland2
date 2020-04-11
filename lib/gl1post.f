: shutdown
    deinit
    al_uninstall_system
;
: empty  shutdown empty ;
: go
    kbs0 /ALLEGRO_KEYBOARD_STATE erase
    kbs1 /ALLEGRO_KEYBOARD_STATE erase
    al_uninstall_keyboard  al_install_keyboard drop
    queue al_get_keyboard_event_source al_register_event_source
    begin
        me >r update r> to me
        display al_flip_display
        \ [ dev ] [if] pause pause pause [then]
        [ dev ] [if] flushOP-gen drop [then]
        kbs0 kbs1 /ALLEGRO_KEYBOARD_STATE move
        kbs0 al_get_keyboard_state
        ms0 ms1 /ALLEGRO_MOUSE_STATE move
        ms0 al_get_mouse_state
        [ dev ] [if] system [then]
        begin queue alevt al_get_next_event while pump repeat
        me >r step r> to me
    kbs0 59 al_key_down until
    [ fullscreen ] [if] shutdown bye [then]
;
: init
    init-allegro
    load-data
    init-game
    [ mswin dev and ] [if] vfx-hwnd SetForegroundWindow drop [then]
;
dev fullscreen not and mswin and [if]
    : go
        display al_get_win_window_handle SetForegroundWindow drop
        go
        vfx-hwnd SetForegroundWindow drop
    ;
[then]
: warm
    init
    go
;
: cold
    ." Hemlo" cr
    warm
    shutdown
;

' cold is EntryPoint