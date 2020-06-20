empty only forth definitions
include lib/gl1pre        \ Load prelude of game lib
require keys.f            \ Key code constants
require lib/filelib.f     \ File ops
require utils.f           \ Miscellanea that I'm used to
require input.f           \ Standard input polling (kb and mouse)
require scene.f           \ Scene system; tilemaps, objects, tileset data
include scenes            \ Define scenes
require script.f          \ Object scripting system
include scripts           \ Load scripts (define behavior for game objects)
include config            \ Configure the game core


include lib/gl1post       \ Load epilogue of game lib; startup, main loop, shutdown
init

0 object as
lemming become
100 p 150 p xy!
