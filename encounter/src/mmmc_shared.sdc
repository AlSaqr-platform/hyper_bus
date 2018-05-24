#################################################################
## Example MMMC SDC files
#################################################################
##
## There are 5 files in this fictional MMMC (multi-mode multi-corner)
## analysis setup:
##   - src/sample/mmmc_shared.sdc        SDC file with common constraints
##   - src/sample/mmmc_functional.sdc    Functional mode constraints
##   - src/sample/mmmc_test.sdc          Test mode constraints
##   - src/sample/mmmc_hold.sdc          Hold timing analysis mode
##   - src/sample/mmmc.view.tcl          Sample TCL file that can be adapted
##
## Please note these are just for reference, develop your own scripts!
##
#################################################################


## You can use a separate file to keep options that are common between
## multiple modes. In this example we will assume that the output load 
## and input transition are the same.

#set_analysis_view -update_timing 

source ../synopsys/netlists/hyperbus_macro.sdc

set period_phy 6.0
set period_sys 4.0

# -edge_shift {[expr $period_phy/4] [expr $period_phy/4]} 
create_generated_clock -name clk0  -source clk_phy_i -edges {1 3 5}  [get_pins i_deflate/i_hyperbus/ddr_clk/clk0_o] 
create_generated_clock -name clk90 -source clk_phy_i -edges {2 4 6} [get_pins i_deflate/i_hyperbus/ddr_clk/clk90_o] 


#Hyperram Datasheet 8.2  -  2V/ns with 20pF load
set_input_transition [expr 1.8 / 2] [get_ports hyper_*_io]

# 
set padDelayInput 1.1
set padDelayOutput 2.0
set insertionDelay [expr $period_phy/4 + $padDelayInput ]

#et_clock_latency -source [expr - $period_phy/2] hyper_rwds_io
set_clock_latency  $insertionDelay hyper_rwds_io

set iddr_cells [list \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_0__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_1__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_2__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_3__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_4__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_5__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_6__i_ddr_in/ddr_neg_reg \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_7__i_ddr_in/ddr_neg_reg \
]

set margin              0.6
set input_clock         hyper_rwds_io;           # Name of input clock
set skew_bre            [expr 0.45 + $margin];   # Data invalid before the rising clock edge
set skew_are            [expr 0.45 + $margin];   # Data invalid after the rising clock edge
set skew_bfe            [expr 0.45 + $margin];   # Data invalid before the falling clock edge
set skew_afe            [expr 0.45 + $margin];   # Data invalid after the falling clock edge
set input_ports         {hyper_dq_io[*]};        # List of input ports

# Input Delay Constraint -source_latency_included
#set_multicycle_path 0 -setup -from $input_ports -to $iddr_cells
set options -network_latency_included
set_input_delay -clock $input_clock -max [expr $period_phy/2 + $skew_afe ] [get_ports $input_ports] $options;
set_input_delay -clock $input_clock -min [expr $period_phy/2 - $skew_bfe ] [get_ports $input_ports] $options;
set_input_delay -clock $input_clock -max [expr $period_phy/2 + $skew_are ] [get_ports $input_ports] -clock_fall -add_delay $options;
set_input_delay -clock $input_clock -min [expr $period_phy/2 - $skew_bre ] [get_ports $input_ports] -clock_fall -add_delay $options;


#set_max_delay -from [get_clocks hyper_rwds_io] -to [get_clocks clk0] 1

#  Double Data Rate Source Synchronous Outputs 
#
#  Source synchronous output interfaces can be constrained either by the max data skew
#  relative to the generated clock or by the destination device setup/hold requirements.
#
#  Setup/Hold Case:
#  Setup and hold requirements for the destination device and board trace delays are known.
#
# forwarded                        _________________________________
# clock                 __________|                                 |______________
#                                 |                                 |
#                           tsu_r |  thd_r                    tsu_f | thd_f
#                         <------>|<------->                <------>|<----->
#                         ________|_________                ________|_______
# data @ destination   XXX__________________XXXXXXXXXXXXXXXX________________XXXXX
#
# Example of creating generated clock at clock output port
create_generated_clock -name hyper_ck_o -edges {1 2 3} -source [get_pins i_deflate/i_hyperbus/ddr_clk/clk90_o] [get_ports hyper_ck_o]
#set_propagated_clock hyper_ck_o
set_clock_latency $padDelayOutput hyper_ck_o
# gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".	

set fwclk        hyper_ck_o;     # forwarded clock name (generated using create_generated_clock at output clock port)        
set tsu_r        0.6+0.5;            # destination device setup time requirement for rising edge
set thd_r        0.6+0.5;            # destination device hold time requirement for rising edge
set tsu_f        0.6+0.5;            # destination device setup time requirement for falling edge
set thd_f        0.6+0.5;            # destination device hold time requirement for falling edge
set output_ports {{hyper_dq_io[*]} hyper_rwds_io};   # list of output ports

# Output Delay Constraints
set_output_delay -clock $fwclk -max [expr                 $tsu_r] [get_ports $output_ports];
set_output_delay -clock $fwclk -min [expr $period_phy/2 - $thd_r] [get_ports $output_ports];
set_output_delay -clock $fwclk -max [expr                 $tsu_f] [get_ports $output_ports] -clock_fall -add_delay;
set_output_delay -clock $fwclk -min [expr $period_phy/2 - $thd_f] [get_ports $output_ports] -clock_fall -add_delay;

set_load 10 [get_ports $output_ports]


set_max_delay \
    -from i_deflate/i_hyperbus/phy_i/hyper_dq_oe_o_reg/Q \
    -to [get_ports $output_ports] \
    [expr $period_phy/2.0]

set_max_delay \
    -from i_deflate/i_hyperbus/phy_i/hyper_rwds_oe_o_reg/Q \
    -to [get_ports $output_ports] \
    [expr $period_phy/2.0]



# false paths through cdc_2phase cells
set CDC_NETS_2PHASE [get_nets -hierarchical {*async_req *async_ack *async_data*}]
set_max_delay \
    -from [all_fanin -to $CDC_NETS_2PHASE -flat -only_cells] \
    -to [all_fanout -from $CDC_NETS_2PHASE -flat -only_cells] \
    [expr $period_sys/2.0]

# false paths through cdc_fifo cells
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *src_wptr_gray_q*] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *dst_wptr_gray_q*] -flat -only_cells] \
    [expr $period_sys/2.0 + $period_phy/2.0]
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *dst_rptr_gray_q*] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *src_rptr_gray_q*] -flat -only_cells] \
    [expr $period_sys/2.0 + $period_phy/2.0]
set_max_delay \
    -from [all_fanin -to [get_nets -hierarchical *fifo_data_q*] -flat -only_cells] \
    -to [all_fanout -from [get_nets -hierarchical *dst_data_o*] -flat -only_cells] \
    [expr $period_sys/2.0 + $period_phy/2.0]

#set_max_delay -from [get_clocks hyper_rwds_io] -to [get_clocks clk0]  [expr $period_sys/2.0 + $insertionDelay]

# false paths for other signals
set CDC_FALSE_PATHS [get_nets -hierarchical {*config_t_* *read_clk_en_i}]
set_max_delay \
    -from [all_fanin -to $CDC_FALSE_PATHS -flat -only_cells] \
    -to [all_fanout -from $CDC_FALSE_PATHS -flat -only_cells] \
    $period_sys

set_false_path -from [get_pins i_deflate/i_hyperbus/ddr_clk/clk0_o] -to [get_ports hyper_*_io]

#set value of delayline
# for {set i 0} {$i < 8} {incr i} {
#     set_case_analysis [expr $i == 0] [get_pins i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/progdel8_i/S[$i]]
# }
