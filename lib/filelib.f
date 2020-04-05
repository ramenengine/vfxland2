0 value file1
: file[  ( zstr - ) zcount cr 2dup type r/w open-file abort" Open file error" to file1 ;
: ]file  file1 close-file abort" Close file error" ;
: bytes-left  file1 file-size abort" Get file size error" drop file1 file-position
    abort" Get file position error" drop - ;
: repos  ( n - ) 0 file1 reposition-file abort" Reposition file error" ;
: read  ( adr bytes - ) file1 read-file abort" Read file error" drop ;
: write ( adr bytes - ) file1 write-file abort" Write file error" drop ;
: newfile[  ( size zstr - ) file[ 0 file1 resize-file abort" Resize file error" ;
