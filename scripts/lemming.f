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
    <left> held if x 0.25e f- x! 0 flip! 0.25e +counter then
    <right> held if x 0.25e f+ x! 1 flip! 0.25e +counter then
    counter walk_a frame ixy!
;
