empty only forth definitions

include lib/fixed.f
include lib/roger.f
include lib/stackarray.f
include lib/game.f

require lib/pv2d.f        \ Fixed-point vectors
require keys.f            \ Key code constants
require lib/filelib.f     \ File ops
require utils.f           \ Miscellanea that I'm used to
require input.f           \ Standard input polling (kb and mouse)
require scene.f           \ Scene system; tilemaps, objects, tileset data
require script.f          \ Object scripting system

include scenes.f          \ Define scenes
include scripts.f         \ Load scripts (define behavior for game objects)

include config.f          \ Configure the game core


include lib/go.f          \ Load epilogue of game lib; startup, main loop, shutdown
init

0 object as
lemming become
100 p 150 p xy!
