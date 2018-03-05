#! /bin/tcsh -f

set VER=10.5a
set LIB=work

vsim-${VER} -work ${LIB} hyperbus_phy_tb -voptargs=+acc
