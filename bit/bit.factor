! File: cnc.bit
! Version: 0.1
! DRI: Dave Carlton
! Description: Another fine Factor file!
! Copyright (C) 2022 Dave Carlton.
! See http://factorcode.org/license.txt for BSD license.

USING: accessors alien.enums alien.syntax cnc cnc.jobs db.tuples
db.types kernel uuid ;

IN: cnc.bit

ENUM: units +mm+ +in+ ;

TUPLE: bit id name size unit type flutes shank edge length manf url cost note ;

bit "BITS" {
    { "id" "ID" +db-assigned-id+ }
    { "name" "NAME" TEXT }
    { "size" "SIZE" DOUBLE }
    { "unit" "UNIT" INTEGER }
    { "type" "TYPE" INTEGER }
    { "flutes" "FLUTES" INTEGER }
    { "shank" "SHANK" DOUBLE }
    { "edge" "EDGE" DOUBLE }
    { "length" "LENGTH" DOUBLE }
    { "manf" "MANF" TEXT }
    { "url" "URL" URL }
    { "cost" "COST" DOUBLE }
    { "note" "NOTE" TEXT }
} define-persistent


ENUM: bitType +straight+ +up+ +down+ +compression+ ;

: <bit> ( name size unit type flutes shank edge length manf url -- bit )
    bit new
    swap >>url
    swap >>manf
    swap >>length
    swap >>edge
    swap >>shank
    swap >>flutes
    swap enum>number >>type
    swap enum>number >>unit
    swap >>size
    swap >>name ;

:: find-bit ( named --  bit )
    [ T{ bit { name named } } select-tuple ] with-jobs-db  ;

:: find-bit-id ( ID -- bit )
    [ T{ bit { id ID } } select-tuple ] with-jobs-db  ;
