require utils.f

1 value nextid

: one-object  ( prefab# - ) 
    max-objects 0 do
        i object [[ en not if
            become nextid id! 1 +to nextid
            at@ 2s>f xy!
        me ]] unloop exit then
        ]] 
    loop -1 abort" Out of object mem."
;

: dismiss  ( object - ) [[ 0 en! 0 id! ]] ;