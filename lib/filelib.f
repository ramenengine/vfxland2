0 value file1
: file[  ( zstr - ) zcount cr 2dup type r/w open-file abort" Open file error" to file1 ;
: ]file  file1 close-file drop ; \ abort" Close file error" ;
: bytes-left  file1 file-size abort" Get file size error" drop file1 file-position
    abort" Get file position error" drop - ;
: repos  ( n - ) 0 file1 reposition-file abort" Reposition file error" ;
: read  ( adr bytes - ) file1 read-file abort" Read file error" drop ;
: write ( adr bytes - ) file1 write-file abort" Write file error" ;
: newfile[  ( size zstr - )
    dup zcount fileExist? if
        zcount cr 2dup type w/o create-file abort" Create file error" to file1 
    else file[ 0 file1 resize-file abort" Resize file error" then ;
        
