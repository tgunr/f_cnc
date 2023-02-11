! File: cnc.bit
! Version: 0.1
! DRI: Dave Carlton
! Description: CNC bit data
! Copyright (C) 2022 Dave Carlton.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.enums alien.syntax classes.tuple cnc
cnc.jobs db db.sqlite db.tuples db.types kernel math math.parser namespaces
quotations sequences uuid variables ;
IN: cnc.bit

! TUPLE: bit id name size unit type flutes shank edge length manf url cost note ;

! bit "BITS" {
!     { "id" "ID" +db-assigned-id+ }
!     { "name" "NAME" TEXT }
!     { "size" "SIZE" DOUBLE }
!     { "unit" "UNIT" INTEGER }
!     { "type" "TYPE" INTEGER }
!     { "flutes" "FLUTES" INTEGER }
!     { "shank" "SHANK" DOUBLE }
!     { "edge" "EDGE" DOUBLE }
!     { "length" "LENGTH" DOUBLE }
!     { "manf" "MANF" TEXT }
!     { "url" "URL" URL }
!     { "cost" "COST" DOUBLE }
!     { "note" "NOTE" TEXT }
! } define-persistent


ENUM: bitType +straight+ +up+ +down+ +compression+ ;

! : <bit> ( name size unit type flutes shank edge length manf url -- bit )
!     bit new
!     swap >>url
!     swap >>manf
!     swap >>length
!     swap >>edge
!     swap >>shank
!     swap >>flutes
!     swap enum>number >>type
!     swap enum>number >>unit
!     swap >>size
!     swap >>name ;

TUPLE: bit
    name_format
    tool_type 
    diameter 
    units 
    feed_rate 
    rate_units 
    plunge_rate 
    spindle_speed 
    spindle_dir 
    stepdown 
    stepover 
    length_units
    id
;

! TUPLE: amana-bit1
!     name_format
!     { tool_type integer }
!     { diameter real }
!     { units integer }
!     { feed_rate integer }
!     { rate_units integer }
!     { plunge_rate integer }
!     { spindle_speed integer }
!     { spindle_dir integer }
!     { stepdown real }
!     { stepover real }
!     { clear_stepover real }
!     { length_units integer } ;

bit "amana" {
    { "name_format" "name_format" TEXT }
    { "tool_type" "tool_type" INTEGER }
    { "diameter" "diameter" DOUBLE }
    { "units" "units" INTEGER }
    { "feed_rate" "feed_rate" INTEGER }
    { "rate_units" "rate_units" INTEGER }
    { "plunge_rate" "plunge_rate" INTEGER }
    { "spindle_speed" "spindle_speed" INTEGER }
    { "spindle_dir" "spindle_dir" INTEGER }
    { "stepdown" "stepdown" DOUBLE }
    { "length_units" "length_units" INTEGER }
    { "id" "id" INTEGER }
} define-persistent

SYMBOL: amana-db-path
INITIALIZE: amana-db-path "/Users/davec/Dropbox/Family Room/3CL/Data/amanavt.db" ; 
SYMBOL: amana-db
INITIALIZE: amana-db "/Users/davec/Dropbox/Family Room/3CL/Data/Amana.db" ;

: (>mm) ( bit slot-value -- mm-value bit )
    >number 25.4 * swap ;

: >mm ( bit -- bit )
    [ dup diameter>> (>mm) diameter<< ] keep
    [ dup feed_rate>> (>mm) feed_rate<< ] keep
    [ dup plunge_rate>> (>mm) plunge_rate<< ] keep
    [ dup stepdown>> (>mm) stepdown<< ] keep
    [ dup stepover>> (>mm) stepover<< ] keep
    ;

TUPLE: amana < sqlite-db ;
: <amana> ( -- <amana> )
    amana new
    amana-db get >>path ;

: with-amana-db ( quot -- )
    '[ <amana> _ with-db ] call ; inline

CONSTANT: toolgeometry "tool_geometry."
CONSTANT: tooldata "tool_cutting_data."

! : tool-preamble ( -- sql )
!     "SELECT
! 	tool_geometry.name_format,
! 	tool_geometry.tool_type,
! 	tool_geometry.diameter,
! 	tool_geometry.units,
! 	tool_cutting_data.feed_rate,
! 	tool_cutting_data.rate_units,
! 	tool_cutting_data.plunge_rate,
! 	tool_cutting_data.spindle_speed,
! 	tool_cutting_data.spindle_dir,
! 	tool_cutting_data.stepdown,
! 	tool_cutting_data.stepover,
! 	tool_cutting_data.clear_stepover,
! 	tool_cutting_data.length_units,
! 	tool_cutting_data.id,
! 	tool_geometry.id
!     FROM
! 	tool_cutting_data
! 	JOIN tool_entity ON tool_cutting_data.id = tool_entity.tool_cutting_data_id
! 	JOIN tool_geometry ON tool_geometry.id = tool_entity.tool_geometry_id
!     WHERE
!     "
!     [  CHAR: \x09 dupd =  over  CHAR: \x0a = or   [ drop CHAR: \x20 ] when  ] map 
!     ;

: tool-preamble ( -- sql )
    "SELECT
	name_format,
	tool_type,
	diameter,
	units,
	feed_rate,
	rate_units,
	plunge_rate,
	spindle_speed,
	spindle_dir,
	stepdown,
	stepover,
	length_units,
    id
    FROM
	amana
    WHERE
    "
    [  CHAR: \x09 dupd =  over  CHAR: \x0a = or   [ drop CHAR: \x20 ] when  ] map 
    ;


: geometry-clause  ( string -- clause )
    toolgeometry prepend ;

: data-clause ( string -- clause )
    tooldata prepend ;

SYMBOL: sql-statement 
: bit-clause1 ( clauses -- )
    [ geometry-clause " and " append ] map
    "" swap [ append ] each
    "tool_cutting_data.feed_rate not null" append
    tool-preamble prepend
    sql-statement set ;

: bit-clause ( clauses -- )
    [  " and " append ] map
    "" swap [ append ] each
    "feed_rate not null" append
    tool-preamble prepend
    sql-statement set ;

: (bit-find) ( clauses -- bits )
    bit-clause [ sql-statement get sql-query ] with-amana-db ;

: find-bit ( clauses -- seq )
    (bit-find)  [ bit slots>tuple ] map
    ;

: find-bit-names ( named --  bit )
    "name_format LIKE " prepend { } 1sequence  (bit-find) ; 

: find-bit-id ( string -- bit )
    "'" prepend  "'" append
    "id = "  prepend
    tool-preamble prepend
    sql-statement set
    [ sql-statement get sql-query ] with-amana-db
    [ bit slots>tuple ] map  first
    ;

: 1/4-bits ( -- bits )
    { "diameter = 0.25" "units = 1" }
    find-bit ;

: resurface-bit ( -- bit )
    "a7f018eb-9bb9-4540-8536-b6d6ffb453e4" find-bit-id  >mm
    0.5 >>stepdown
    0 >>units ; 
