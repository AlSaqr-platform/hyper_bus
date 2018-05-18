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

#set_input_transition 1.0 [get_ports hyper_*_io]
#set_input_delay -clock clk_rwds 0 [get_ports hyper_*_io]
#set_load 20.0 [get_ports hyper_*o]
#set_output_delay -clock clk0 0 [get_ports hyper_*o]

#set value of delayline
for {set i 0} {$i < 8} {incr i} {
    set_case_analysis [expr $i == 0] [get_pins i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/progdel8_i/S[$i]]
}
