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

## In our fictional example the circuit has a main operational mode
## In a standard SDC file (without MMMC) we would only use these
## constraints. 

# create_clock -period  8 [get_ports {Clk_CI}]

# set_input_delay  2 -clock {Clk_CI} [remove_from_collection [all_inputs] [get_ports {Clk_CI}]]
# set_output_delay 3 -clock {Clk_CI} [all_outputs]

## In this mode, the following pin is always set to the given value
# set_case_analysis 0 [get_ports {ScanEn_TI}]
# set_case_analysis 0 [get_ports {RamTest_TI}]

## set_case_analysis sets a constant value
## ste_false_path removes it from timing calculation.
## Use set_false_path as a last resort. 
#set_false_path -from [get_ports {ScanEn_TI}]
#set_false_path -from [get_ports {RamTest_TI}]

# current_instance i_hyperbus
# source ../synopsys/netlists/hyperbus.sdc
