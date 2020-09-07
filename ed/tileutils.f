require ed/utils.f

0 value src-stride
0 value dest-stride

: stride  ( src-stride dest-stride -- )
    to dest-stride to src-stride ;

: moverow ( src dest bytes -- src+stride dest+stride bytes )
    >r over over r@ move src-stride dest-stride 2+ r> ;

: 2move ( src dest bytes rows -- )
    0 ?do moverow loop drop drop drop ;

: 2erase ( dest bytes rows stride -- )
    to dest-stride 0 ?do 2dup erase swap dest-stride + swap loop drop drop ;

: 2tfill ( dest cols rows stride n -- ) | n |
    to dest-stride 0 ?do 2dup cells bounds ?do n i ! loop swap dest-stride + swap loop
    drop drop ;

: tmove ( src-tilemap dest-tilemap x y -- )  \ negative x,y currently not supported
    0 max swap 0 max | x y dest src |
    src 's tm.stride  dest 's tm.stride  stride
    src 's tm.base                                   \ source address is always at 0,0
        dest 's tm.base x cells + y dest-stride * +  \ calculate destination addr
        src 's tm.cols  dest 's tm.cols x - min 0 max  cells
        src 's tm.rows  dest 's tm.rows y - min 0 max  2move ; 
