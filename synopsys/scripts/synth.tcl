
set UNIT "hyperbus"

# ------------------------------------------------------------------------------
# Remove all current designs and the directory of the library.
# ------------------------------------------------------------------------------
remove_design -all
sh rm -rf WORK/*

set_host_options -max_cores 3

# ------------------------------------------------------------------------------
# Analyze Design
# ------------------------------------------------------------------------------
analyze -library WORK -format sverilog [list \
    ../src/tech_cells_UMC65/pulp_clock_xor2_umc65.sv \
    ../src/tech_cells_UMC65/pulp_clock_mux2_umc65.sv \
    ../src/tech_cells_UMC65/pulp_clock_gating_umc65.sv \
    ../src/tech_cells_UMC65/pulp_clock_inverter_umc65.sv \
    ../src/common_cells/src/cdc_fifo_gray.sv \
    ../src/common_cells/src/cdc_2phase.sv \
    ../src/common_cells/src/graycode.sv \
    ../src/axi/src/axi_pkg.sv \
    ../src/axi/src/axi_intf.sv \
    ../src/register_interface/src/reg_intf.sv \
    ../src/register_interface/src/reg_uniform.sv \
    ../src/delayline/PROGDEL8.v \
    ../src/config_registers.sv \
    ../src/clock_diff_out.sv \
    ../src/clk_gen.sv \
    ../src/ddr_out.sv \
    ../src/hyperbus_delay_line.sv \
    ../src/read_clk_rwds.sv \
    ../src/hyperbus.sv \
    ../src/hyperbus_phy.sv \
    ../src/hyperbus_axi.sv \
    ../src/cmd_addr_gen.sv \
    ../src/ddr_in.sv \
]

# ------------------------------------------------------------------------------
# Elaborate Design
# ------------------------------------------------------------------------------
elaborate hyperbus_inflate -parameters "AXI_IW => 10"

set period_sys 2
set period_phy 3

# ------------------------------------------------------------------------------
# Define Constraints
# ------------------------------------------------------------------------------
# set_max_area 0
# Setting the clock period.
create_clock clk_i -period $period_phy
# create_clock clk_sys_i -period 2

create_generated_clock -name clk0   -source clk_i -divide_by 2  [get_pins i_deflate/ddr_clk/clk0_o] 
create_generated_clock -name clk90  -source clk_i -divide_by 2  -edge_shift {1.5 1.5} [get_pins i_deflate/ddr_clk/clk90_o] 
create_generated_clock -name clk180 -source clk_i -divide_by 2  -edge_shift {3 3} [get_pins i_deflate/ddr_clk/clk180_o] 
create_generated_clock -name clk270 -source clk_i -divide_by 2  -edge_shift {4.5 4.5} [get_pins i_deflate/ddr_clk/clk270_o] 

create_clock -name clk_rwds -period [expr 2*$period_phy] [get_ports hyper_rwds_i]

# Setting input and output delays.
set DELAY_A [expr $period_sys * 1.0 / 3]
set DELAY_B [expr $period_sys * 2.0 / 3]

#add cfg with OR
set CHIN  "name=~axi_i_a*  OR name=~axi_i_w*" 
set CHOUT "name=~axi_i_b*  OR name=~axi_i_r*"

set_input_delay $DELAY_A  [filter_collection [all_inputs]  $CHIN]  -clock clk_i -source_latency_included
set_input_delay $DELAY_B  [filter_collection [all_inputs]  $CHOUT] -clock clk_i -source_latency_included
set_output_delay $DELAY_A [filter_collection [all_outputs] $CHIN]  -clock clk_i -source_latency_included
set_output_delay $DELAY_B [filter_collection [all_outputs] $CHOUT] -clock clk_i -source_latency_included

# false paths through cdc_2phase cells
set CDC_NETS_2PHASE [get_nets -hierarchical {*async_req *async_ack *async_data}]
set_max_delay \
    -from [all_fanin -to $CDC_NETS_2PHASE -flat -only_cells] \
    -to [all_fanout -from $CDC_NETS_2PHASE -flat -only_cells] \
    [expr $period_sys/2.0]

# false paths through cdc_fifo cells
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *src_wptr_gray_q] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *dst_wptr_gray_q] -flat -only_cells] \
    [expr $period_sys/2.0]
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *dst_rptr_gray_q] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *src_rptr_gray_q] -flat -only_cells] \
    [expr $period_sys/2.0]
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *fifo_data_q] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *dst_data_o] -flat -only_cells] \
    [expr $period_sys/2.0]

# false paths for other signals
set CDC_FALSE_PATHS [get_nets -hierarchical {*config_t_* *read_clk_en_i}]
set_max_delay \
    -from [all_fanin -to $CDC_FALSE_PATHS -flat -only_cells] \
    -to [all_fanout -from $CDC_FALSE_PATHS -flat -only_cells] \
    $period_sys

set_max_delay -from [get_ports hyper_rwds_i] -to [all_registers -data_pins] [expr $period_sys/2.0]


set_dont_touch [get_designs hyperbus_delay_line]
#report_dont_touch

# set_input_delay 0.4 -clock clk90  hyper_rwds_i 
# set_input_delay 0.4 -clock clk90  {hyper_dq_i}
# set_input_delay  0.4 -clock clk_i [get_ports axi*]

# set_output_delay 0.4 -clock clk_i [all_outputs]

# set_output_delay 0.4 -clock clk90  hyper_rwds_i
# set_output_delay 0.4 -clock clk90  {hyper_dq_i[7] hyper_dq_i[6] hyper_dq_i[5] hyper_dq_i[4] hyper_dq_i[3] hyper_dq_i[2] hyper_dq_i[1] hyper_dq_i[1]}

# Set input driver and output load.
set_driving_cell -no_design_rule -lib_cell BUFM4W -pin Z -library uk65lscllmvbbl_120c25_tc [remove_from_collection [all_inputs] clk_i]
set_load [expr 8 * [load_of uk65lscllmvbbl_120c25_tc/BUFM4W/A]] [all_output]

# Compilation after setting constraints.
compile_ultra -no_autoungroup

rename_design [current_design] hyperbus_inflate

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

write_sdc -nosplit ./netlists/${UNIT}.sdc