#! /bin/tcsh -f

# example file to compile GATE-LEVEL sourcecode


set VER=10.6b
set LIB=gate


if (-e ${LIB}) then
  rm -rf ${LIB}
endif

vlib-${VER} ${LIB}

# gate-level netlist
vlog-${VER} -work ${LIB} ../encounter/out/hyperbus_macro.v

#hyperram model
vlog-${VER} -work ${LIB} ../models/s27ks0641/s27ks0641.v

# testbench
vlog-${VER} -sv -work ${LIB} \
    ../src/axi/src/axi_pkg.sv \
    ../src/axi/src/axi_intf.sv \
    ../src/axi/src/axi_test.sv \
    ../src/register_interface/src/reg_intf.sv \
    ../src/register_interface/src/reg_test.sv \
    ../src/pad_io.sv \
    ../src/hyperbus_macro.sv \
    ../src/hyperbus_tb.sv \
    ../src/hyperbus_phy_tb.sv


# run with the sim_postlayout.csh script
