
set UNIT "hyperbus"

# ------------------------------------------------------------------------------
# Remove all current designs and the directory of the library.
# ------------------------------------------------------------------------------
remove_design -all
sh rm -rf WORK/*

# ------------------------------------------------------------------------------
# Analyze Design
# ------------------------------------------------------------------------------
analyze -library WORK -format sverilog {
    ../src/tech_cells_generic/pulp_clock_xor2.sv \
    ../src/tech_cells_generic/pulp_clock_mux2.sv \
    ../src/tech_cells_generic/pulp_clock_gating.sv \
    ../src/tech_cells_generic/pulp_clock_inverter.sv \
    ../src/common_cells/src/cdc_fifo_gray.sv \
    ../src/common_cells/src/cdc_2phase.sv \
    ../src/common_cells/src/graycode.sv \
    ../src/axi/src/axi_pkg.sv \
    ../src/axi/src/axi_intf.sv \
    ../src/register_interface/src/reg_intf.sv \
    ../src/register_interface/src/reg_uniform.sv \
    ../src/config_registers.sv \
    ../src/clock_diff_out.sv \
    ../src/clk_gen.sv \
    ../src/ddr_out.sv \
    ../src/delay_line.sv \
    ../src/read_clk_rwds.sv \
    ../src/hyperbus.sv \
    ../src/hyperbus_phy.sv \
    ../src/hyperbus_axi.sv \
    ../src/cmd_addr_gen.sv \
    ../src/ddr_in.sv \
}

# ------------------------------------------------------------------------------
# Elaborate Design
# ------------------------------------------------------------------------------
elaborate hyperbus

# ------------------------------------------------------------------------------
# Define Constraints
# ------------------------------------------------------------------------------
set_max_area 0
# Setting the clock period.
create_clock clk_i -period 6
create_generated_clock -source clk_i -divide_by 2  [get_pins ddr_clk/clk0_o] 
create_generated_clock -source clk_i -divide_by 2  -edge_shift {1.5 1.5} [get_pins ddr_clk/clk90_o] 
create_generated_clock -source clk_i -divide_by 2  -edge_shift {3 3} [get_pins ddr_clk/clk180_o] 
create_generated_clock -source clk_i -divide_by 2  -edge_shift {4.5 4.5} [get_pins ddr_clk/clk270_o] 

# Setting input and output delays.
set_input_delay  0.4 -clock clk_i [all_inputs]
set_output_delay 0.4 -clock clk_i [all_outputs]

# Set input driver and output load.
set_driving_cell -no_design_rule -lib_cell BUFM4W -pin Z -library uk65lscllmvbbl_120c25_tc [remove_from_collection [all_inputs] clk_i]
set_load [expr 8 * [load_of uk65lscllmvbbl_120c25_tc/BUFM4W/A]] [all_output]

# Compilation after setting constraints.
compile_ultra -no_autoungroup

# ------------------------------------------------------------------------------
# Generate Reports
# ------------------------------------------------------------------------------
report_timing > reports/hyperbus_timing.rpt
report_area -hierarchy > reports/hyperbus_area.rpt
report_cell -nosplit [all_registers] > reports/hyperbus_registers.rpt
report_reference -nosplit > reports/hyperbus_references.rpt

report_timing -from [all_registers -output_pins] -to [all_registers -data_pins] > reports/hyperbus_tss.rpt
report_timing -from [all_inputs]                 -to [all_registers -data_pins] > reports/hyperbus_tis.rpt
report_timing -from [all_registers -output_pins] -to [all_outputs]              > reports/hyperbus_tso.rpt
report_timing -from [all_inputs]                 -to [all_outputs]              > reports/hyperbus_tio.rpt


# ---------------------------------------------------------
# save
# ---------------------------------------------------------
write_file -format ddc -hierarchy -output ./DDC/${UNIT}.ddc

define_name_rules verilog -add_dummy_nets 
change_names -rules verilog -hier
write_file -format verilog -hierarchy -output ./netlists/${UNIT}.v
