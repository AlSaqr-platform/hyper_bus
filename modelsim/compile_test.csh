#! /bin/tcsh -f

set VER=10.6b
set LIB=work


if (-e ${LIB}) then
  rm -rf ${LIB}
endif

vlib-${VER} ${LIB}

vlog-${VER} -work ${LIB} ../models/s27ks0641/s27ks0641.v

vlog-${VER} -sv -work ${LIB} \
	../src/tech_cells_generic/pulp_clock_xor2.sv \
	../src/tech_cells_generic/pulp_clock_mux2.sv \
	../src/tech_cells_generic/pulp_clock_gating.sv \
	../src/tech_cells_generic/pulp_clock_inverter.sv \
	../src/clk_gen.sv \
	../src/ddr_out.sv \
	../src/pad_simulation.sv \
	../src/hyperbus.sv \
	../src/hyperbus_phy.sv \
	../src/cmd_addr_gen.sv \
	../src/ddr_in.sv \
	../src/hyperbus_tb.sv \
	../src/hyperbus_phy_tb.sv
