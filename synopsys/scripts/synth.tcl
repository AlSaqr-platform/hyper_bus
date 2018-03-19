

analyze -library WORK -format sverilog {/scratch/hyperbus/src/output_fifo.sv /scratch/hyperbus/src/input_fifo.sv /scratch/hyperbus/src/hyperbus_phy.sv /scratch/hyperbus/src/ddr_out.sv /scratch/hyperbus/src/ddr_in.sv /scratch/hyperbus/src/cmd_addr_gen.sv /scratch/hyperbus/src/clk_gen.sv /scratch/hyperbus/src/tech_cells_generic/pulp_clock_gating.sv /scratch/hyperbus/src/tech_cells_generic/pulp_clock_inverter.sv /scratch/hyperbus/src/tech_cells_generic/pulp_clock_mux2.sv }

elaborate hyperbus_phy -architecture verilog -library WORK

compile_ultra