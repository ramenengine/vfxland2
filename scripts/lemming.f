prefab: lemming
    224 ix! 0 iy!
;prefab

: extensions:  /userfields ;
: ;extensions  drop ;

extensions:
    include anim.f
;extensions

anim: walk_a 15 , 14 , 13 , 12 , 11 , 10 , 9 , 8 , ;anim

lemming :: think
    <left> held if x -25 % + x! 0 flip! 25 % +counter then
    <right> held if x 25 % + x! 1 flip! 25 % +counter then
    counter walk_a frame ixy!
;
