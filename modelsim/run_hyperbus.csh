#! /bin/tcsh -f

set VER=10.6b
set LIB=work

vsim-${VER} -t 1ps -work ${LIB} hyperbus_tb -voptargs=+acc
