onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hyperbus_tb/fix/i_dut/clk_phy_i
add wave -noupdate /hyperbus_tb/fix/i_dut/clk_sys_i
add wave -noupdate /hyperbus_tb/fix/i_dut/rst_ni
add wave -noupdate /hyperbus_tb/fix/i_dut/test_mode_i
add wave -noupdate -divider {Register Bus}
add wave -noupdate /hyperbus_tb/fix/i_dut/reg_req_i
add wave -noupdate /hyperbus_tb/fix/i_dut/reg_rsp_o
add wave -noupdate -divider {AXI Bus}
add wave -noupdate /hyperbus_tb/fix/i_dut/axi_req_i
add wave -noupdate /hyperbus_tb/fix/i_dut/axi_rsp_o
add wave -noupdate -divider {Hyperbus Chip}
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/CSNeg
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/CK
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/CKNeg
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/RESETNeg
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ7
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ6
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ5
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ4
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ3
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ2
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ1
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ0
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/RWDS
add wave -noupdate -divider {Hyper i/o}
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_cs_no
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_ck_o
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_ck_no
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_reset_no
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_dq_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_dq_o
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_rwds_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_rwds_o
add wave -noupdate /hyperbus_tb/fix/i_dut/hyper_dq_i
add wave -noupdate -divider Debug
add wave -noupdate /hyperbus_tb/fix/i_dut/debug_hyper_phy_state_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7480 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 299
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {147388 ps}
