! Version: 0.1
! DRI: Dave Carlton
! Description: CNC Jobs
! Copyright (C) 2022 Dave Carlton.
! See http://factorcode.org/license.txt for BSD license.
USING: db db.sqlite io.files kernel unix ;
IN: cnc.jobs

TUPLE: jobs { path initial: "/Users/davec/Dropbox/3CL/Jobs/jobs.db" } db handle ;

: maybe-create ( path -- path )
    dup file-exists?
    [ dup open-rw close-file ] unless
    ;

: <jobs> ( -- jobs )
    jobs new
    ;

: with-jobs-db ( quot -- )
    '[ "/Users/davec/Dropbox/3CL/Jobs/jobs.db"
       <sqlite-db> _ with-db
    ] call ; inline


  
