! File: cnc.tools
! Version: 0.1
! DRI: Dave Carlton
! Description: Another fine Factor file!
! Copyright (C) 2022 Dave Carlton.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors cnc cnc.gcode cnc.job cnc.jobs cnc.machine formatting
io kernel math multiline sequences io.encodings.utf8 io.files math.parser
    command-line namespaces variables generalizations sequences.generalizations prettyprint ;
FROM: cnc.gcode => f ;
IN: cnc.tools

TUPLE: toolpath  id machine bitsize speed feed step depth gcode ;
: <toolpath> ( machine bitsize speed feed depth -- toolpath )
    toolpath new
    swap >>depth
    swap >>feed
    swap >>speed
    over .7 * >>step ! 70% stepover
    swap >>bitsize
    swap >>machine
    ;

:: do-x ( gcodes x ymax step -- gcodes )
    gcodes
    x ymax          "X %.02f Y %.02f" sprintf  suffix
    x step +  ymax  "X %.02f Y %.02f" sprintf  suffix
    x step +  0     "X %.02f Y %.02f" sprintf  suffix
    ;

:: surface-x ( gcodes toolpath -- gcodes )  ! assume starts at home, ends at home
    toolpath machine>> x-max>> :> xmax
    toolpath machine>> y-max>> :> ymax
    0 :> x!  0 :> y! 
    gcodes
    [ x xmax <= ]
    (( up over down over ))
    [   x ymax toolpath step>> do-x
        x toolpath step>> 2 * + x!
        x 0     "X %.02f Y %.02f" sprintf  suffix
    ]  while
    but-last
    ;
 
:: do-y ( gcodes y xmax step -- gcodes )
    gcodes
    xmax          y "X %.02f Y %.02f" sprintf  suffix
    xmax   y step + "X %.02f Y %.02f" sprintf  suffix
    0      y step + "X %.02f Y %.02f" sprintf  suffix
    ;

:: surface-y ( gcodes toolpath -- gcodes )  ! assume starts at home, ends at home
    toolpath machine>> x-max>> :> xmax
    toolpath machine>> y-max>> :> ymax
    0 :> x!  0 :> y!
    gcodes
    [ y ymax <= ]
    (( across up back up ))
    [   y xmax toolpath step>> do-y
        y toolpath step>> 2 * + y!
        0 y "X %.02f Y %.02f" sprintf  suffix
    ]  while
    but-last
    ;

:: boundary ( toolpath -- )   
    toolpath machine>> x-max>> :> xmax
    toolpath machine>> y-max>> :> ymax
    { }
    90 G +g
    g1 3000 f +g
    g1 10 z +g
    g1 0 x 0 y +g
    g1 xmax x +g
    g1 ymax y +g
    g1 0 x +g
    g1 0 y +g
    [ print ] each
    ;
    
: preamble ( -- {gcodes} )   ! Set absolute, mm, move z up, home, move z down to 1 mm
    { }
    absolute +g  mm +g
    g0 10 z  1500 f +g
    home-xy 1000 f +g
    g0 1 z +g
    ;
        
:: <surface-job> ( xmax ymax -- machine )
    machine new
    "Resurface" "Resurface Job" cnc xmax ymax 133 <init> ;

:: resurfacex ( toolpath -- )
    "~/Desktop/"  toolpath machine>> name>> "-x" append  append  ".gcode" append  :> path
    preamble
    g1 0 x 0 y toolpath feed>> f suffix
    3 M toolpath speed>> s suffix
    g1 toolpath depth>> neg z  suffix
    toolpath surface-x
    g0 10 z  suffix
    g0 0 x 0 y  suffix
    g1 toolpath depth>> neg z  suffix
    92 G  0 z  suffix
    path utf8 [
        [ print ] each
    ] with-file-writer ;

:: resurfacey ( toolpath -- )
    "~/Desktop/"  toolpath machine>> name>> "-y" append  append  ".gcode" append  :> path
    preamble
    g1 0 x 0 y toolpath feed>> f suffix
    3 M toolpath speed>> s  suffix
    g1 toolpath depth>> neg z  suffix
    toolpath surface-y
    g0 10 z  suffix
    g0 0 x 0 y  suffix
    g1 toolpath depth>> neg z  suffix
    92 G  0 z  suffix
    path utf8 [
        [ print ] each
    ] with-file-writer ;

:: bounds-check ( toolpath -- )
    "~/Desktop/"  toolpath machine>> name>> append  " Boundary.gcode" append  utf8  
    [ toolpath boundary ] with-file-writer ;


:: resurface ( xmax ymax bitsize speed feed depth -- )
    xmax ymax <surface-job>  bitsize speed feed depth <toolpath>
    [ resurfacex  ] keep
    [ resurfacey  ] keep
    bounds-check
    ;

GLOBAL: xmax
GLOBAL: ymax
GLOBAL: bitsize
GLOBAL: speed
GLOBAL: feed
GLOBAL: depth
GLOBAL: help

FROM: syntax => f ;
: reset-globals ( -- )
    { "help" "xmax" "ymax" "bitsize" "speed" "feed" "depth" } [ f swap set-global ] each ;
    
: usage ( -- )
    "resurface --xmax=n --ymax=n --bitsize=n --speed=n --feed=n --depth=n" print
    "  All values are in mm" print
    ;

: (resurface-args) ( -- )
    "help" get-global
    [ usage ]
    [
        { "xmax" "ymax" "bitsize" "speed" "feed" "depth" } [ get-global ] map  
        f over member?
        [ drop  usage ] 
        [ [ string>number ] map
          6 firstn  resurface
          "Resurface files have been written to the desktop" print
        ]
        if
    ] if
    ;

: resurface-args ( -- )
    reset-globals
    command-line get parse-command-line  (resurface-args)
    ;

! ./factor -run=cnc.tools --xmax=200 --ymax=200 --bitsize=40 --speed-16000 --feed=3000 --depth=0.5
: resurface-test ( -- )
    reset-globals
    { "factor" "--xmax=200" "--ymax=200" "--bitsize=40" "--speed=16000" "--feed=3000" "--depth=0.5" }
    parse-command-line 
    (resurface-args) ; 
    
MAIN: resurface-args
