#! /bin/bash

PARAMS="../Octavo/Misc/params.v"

clear
qverilog -mfcu -incr -lint -novopt $PARAMS $1
#rm qverilog.log

