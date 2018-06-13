source scripts/read_lib.tcl 


#read_netlist ../synopsys/netlists/hyperbus_macro.v 
read_netlist ../encounter/out/hyperbus_macro.v 


run_build_model hyperbus_macro_inflate 
add_clocks 0 clk_sys_i -shift 
add_clocks 1 rst_ni 
add_scan_chains chain1 scan_in_ti scan_out_to 
add_scan_enables 1 scan_en_ti 
add_pi_constraints 1 test_en_ti 
run_drc 
add_faults -all 
report_summaries 
run_atpg -auto_compression 


report_faults -summary
report_faults -level 3 32 -verbose

write_faults reports/faults-au.rpt -replace -class AU 
write_faults reports/faults-nd.rpt -replace -class ND 
write_faults reports/faults-ud.rpt -replace -class UD 

write_patterns pattern/pattern.wglflat -replace -internal -format wgl_flat -sorted -order_pins

write_testbench -input pattern/pattern.wglflat_stiltmp -output scanchain_tb -replace


