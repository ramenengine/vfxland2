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
    <left> held if x -1 4 p/ + x! 0 flip! 1 4 p/ +counter then
    <right> held if x 1 4 p/ + x! 1 flip! 1 4 p/ +counter then
    counter walk_a aframe ixy!
;
