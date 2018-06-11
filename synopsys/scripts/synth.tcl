
set UNIT "hyperbus_macro"

# ------------------------------------------------------------------------------
# Remove all current designs and the directory of the library.
# ------------------------------------------------------------------------------
remove_design -all
sh rm -rf WORK/*

set target_library [list uk65lscllmvbbl_108c125_wc.db uk65lscllmvbbr_108c125_wc.db uk65lscllmvbbh_108c125_wc.db u065gioll25mvir_25_wc.db]
set link_library   [list "*" uk65lscllmvbbl_108c125_wc.db uk65lscllmvbbr_108c125_wc.db uk65lscllmvbbh_108c125_wc.db u065gioll25mvir_25_wc.db dw_foundation.sldb]


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
    ../src/common_cells/src/rstgen.sv \
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
    ../src/pad_io.sv \
    ../src/hyperbus.sv \
    ../src/hyperbus_macro.sv \
    ../src/hyperbus_phy.sv \
    ../src/hyperbus_axi.sv \
    ../src/cmd_addr_gen.sv \
    ../src/ddr_in.sv \
]

# ------------------------------------------------------------------------------
# Elaborate Design
# ------------------------------------------------------------------------------
elaborate hyperbus_macro_inflate -parameters "AXI_IW => 10"

set period_sys 4.0
set period_phy 6.0

# ------------------------------------------------------------------------------
# Define Constraints
# ------------------------------------------------------------------------------
# set_max_area 0
# Setting the clock period.
create_clock clk_sys_i -period $period_sys
create_clock clk_phy_i -period [expr $period_phy/2]
# create_clock clk_sys_i -period 2

create_generated_clock -name clk0  -source clk_phy_i -edges {1 3 5}  [get_pins i_deflate/i_hyperbus/ddr_clk/clk0_o] 
create_generated_clock -name clk90 -source clk_phy_i -edges {2 4 6} [get_pins i_deflate/i_hyperbus/ddr_clk/clk90_o] 
#create_generated_clock -name clk0   -source clk_phy_i -divide_by 2  [get_pins i_deflate/i_hyperbus/ddr_clk/clk0_o] 
#create_generated_clock -name clk90  -source clk_phy_i -divide_by 2  -edge_shift {1.5 1.5} [get_pins i_deflate/i_hyperbus/ddr_clk/clk90_o]

#create_clock -name clk_rwds -period [expr 2*$period_phy] [get_pins i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/cdc_read_ck_gating/clk_o]
create_clock -period [expr $period_phy] [get_ports hyper_rwds_io]

# Setting input and output delays.
set DELAY_A [expr $period_sys * 1.0 / 3]
set DELAY_B [expr $period_sys * 2.0 / 3]

#add cfg with OR
set CHIN  "name=~axi_i_a*  OR name=~axi_i_w* OR name=~cfg_i_*" 
set CHOUT "name=~axi_i_b*  OR name=~axi_i_r*"

set_case_analysis 0 test_en_ti
set_case_analysis 0 scan_en_ti

set_input_delay $DELAY_A  [filter_collection [all_inputs]  $CHIN]  -clock clk_sys_i -source_latency_included
set_input_delay $DELAY_B  [filter_collection [all_inputs]  $CHOUT] -clock clk_sys_i -source_latency_included
set_output_delay $DELAY_A [filter_collection [all_outputs] $CHIN]  -clock clk_sys_i -source_latency_included
set_output_delay $DELAY_B [filter_collection [all_outputs] $CHOUT] -clock clk_sys_i -source_latency_included

set_output_delay -clock clk0 [expr $period_phy/3] [get_ports debug_hyper*]

# false paths through cdc_2phase cells
set CDC_NETS_2PHASE [get_nets -hierarchical {*async_req *async_ack *async_data*}]
set_max_delay \
    -from [all_fanin -to $CDC_NETS_2PHASE -flat -only_cell] \
    -to [all_fanout -from $CDC_NETS_2PHASE -flat -only_cell] \
    [expr $period_sys/2.0]

# false paths through cdc_fifo cells
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *src_wptr_gray_q*] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *dst_wptr_gray_q*] -flat -only_cells] \
    [expr $period_sys/2.0]
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *dst_rptr_gray_q*] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *src_rptr_gray_q*] -flat -only_cells] \
    [expr $period_sys/2.0]

set_false_path \
    -from [all_fanin -to [get_nets -hierarchical *fifo_data_q*] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *dst_data_o*] -flat -only_cell] 

set_false_path \
    -from [all_fanin -to [get_nets -hierarchical *fifo_data_q*] -flat -only_cells] \
    -to  [get_ports {axi_i_r_resp* axi_i_r_data* axi_i_r_last}]

# false paths for other signals
set CDC_FALSE_PATHS [get_nets -hierarchical {*config_t_* *read_clk_en_i}]
set_max_delay \
    -from [all_fanin -to $CDC_FALSE_PATHS -flat -only_cells] \
    -to [all_fanout -from $CDC_FALSE_PATHS -flat -only_cells] \
    $period_sys

set_max_delay \
    -from [get_pins i_deflate/i_hyperbus/phy_i/hyper_*_oe_o_reg/Q] \
    -to [get_pins i_deflate/pad_hyper_*/OE] \
    [expr $period_phy/2.0]


set_max_delay -from [get_pins i_deflate/i_hyperbus/hyper_rwds_i] -to [get_pins i_deflate/i_hyperbus/phy_i/hyper_rwds_i_syn_reg/next_state] [expr $period_sys/2.0]

set_false_path -hold -from [get_clocks hyper_rwds_io] -to [get_clocks clk0]
set_false_path -hold -from [get_clocks clk0] -to [get_clocks hyper_rwds_io]
set_false_path -hold -from [get_clocks clk0] -to [get_clocks clk_sys_i]
set_false_path -hold -from [get_clocks clk_sys_i] -to [get_clocks clk0]


#set_dont_touch [get_designs PROGDEL8]
#report_dont_touch


# Set input driver and output load.
set_driving_cell -no_design_rule -lib_cell BUFM4W -pin Z -library uk65lscllmvbbl_108c125_wc [remove_from_collection [all_inputs] {clk_sys_i clk_phy_i}]

#set_load [expr 4 * [load_of uk65lscllmvbbl_120c25_tc/BUFM4W/A [all_output]
set_load 0.005 [all_output]
set_load 10 [get_ports {hyper_dq* hyper_rwds_io hyper_ck_* hyper_cs_*}]


# Compilation after setting constraints.
compile_ultra -scan -no_autoungroup -gate_clock
 

# Scan chain 
set_dft_signal -view existing_dft -type ScanClock -port clk_sys_i -timing {50 80} 
set_dft_signal -view existing_dft -type Reset -port rst_ni -active_state 0 
set_dft_signal -view existing_dft -type Constant -port test_en_ti -active_state 1 
 
set_dft_signal -view spec -type ScanEnable -port scan_en_ti -active_state 1 
set_dft_signal -view spec -type ScanDataIn -port scan_in_ti 
set_dft_signal -view spec -type ScanDataOut -port scan_out_to 

set_scan_element false [ get_cells -hierarchical ddr_clk ]
set_scan_element false [ get_cells -hierarchical ddr_neg_reg ]
set_scan_element false [ get_cells -hierarchical pad_* ]

#todo good idea?
set_scan_element false [ get_cells i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/read_in_valid_reg ]

#set_scan_configuration -internal_clocks multi 
create_test_protocol 
 
insert_dft 



rename_design [current_design] hyperbus_macro_inflate

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
