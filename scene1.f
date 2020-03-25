\ a scene system for gamelib1
\ tilesets are loaded by the game and not referenced by scenes

require lib/filelib.f

synonym | locals|
: ]#  ] postpone literal ;

struct /scene
    64 +field s.zpath
end-struct