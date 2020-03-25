order 0 value file1
: file[  ( zstr - ) zcount r/w open-file throw to file1 ;
: ]file  file1 close-file throw ;
: bytes-left  file1 file-size throw drop file1 file-position throw drop - ;
: reposition  ( n - ) 0 file1 reposition-file throw ;
: read  ( adr bytes - ) file1 read-file throw drop ;
: write ( adr bytes - ) file1 write-file throw drop ;
: newfile[  ( size zstr - ) file[ 0 file1 resize-file throw ;
