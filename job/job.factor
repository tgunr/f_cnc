! Version: 0.1
! DRI: Dave Carlton
! Description: CNC Jobs
! Copyright (C) 2022 Dave Carlton.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors cnc.jobs cnc.machine cnc.material db.tuples db.types kernel io
sequences uuid uuid.private ;

IN: cnc.job


TUPLE: job id name date finish client machine material cost note ;

job "JOB" {
    { "id" "ID" +db-assigned-id+ }
    { "name" "NAME" TEXT }
    { "date" "DATE" DATE }
    { "client" "CLIENT" TEXT }
    { "machine" "MACHINE" INTEGER }
    { "material" "MATERIAL" INTEGER }
    { "cost" "COST" DOUBLE }
    { "finish" "FINISH" DATE }
} define-persistent

: <job> ( name machine material -- job )
    job new 
    over find-material >>material
    nip  over find-machine >>machine
    nip swap >>name
    uuid1 >>id
    (timestamp) >>date
    ;

: fix-job ( job -- job )
    ;

: define-jobs ( -- )
    [ job ensure-table ] with-jobs-db ;

:: insert-job ( name machine material -- job )
    [ job ensure-table
      name machine material <job> dup insert-tuple
    ] with-jobs-db ;

: job1 ( -- job )
    "Test" "SM2 CNC" "Red Oak" insert-job ;

