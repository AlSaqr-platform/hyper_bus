onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hyperbus_tb/fix/i_dut/axi_req_i
add wave -noupdate /hyperbus_tb/fix/i_dut/axi_rsp_o
add wave -noupdate -divider {Narrow AXI}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/narrow_req
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/narrow_rsp
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_q
add wave -noupdate -divider {4-channel (soc)}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rx_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rx_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rx_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/tx_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/tx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/tx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/b_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/b_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_cs_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_q
add wave -noupdate -divider {4-channels (PHY)}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/clk_0_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_cs_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_ready_o
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_phy/tx_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_ready_i
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_phy/rx_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_ready_i
add wave -noupdate -divider PHY
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_q
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_phy/tf_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cs_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/timer_q
add wave -noupdate -divider TRX
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/clk_0_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/clk_90_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/clk_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/clk_test_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/cs_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/cs_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_ck_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_ck_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_cs_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_dq_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_dq_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_dq_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_reset_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_rwds_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_rwds_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/NumChips
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rst_ni
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rwds_sample_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rwds_sample_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_clk_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_data_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk_orig
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_data_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_fifo_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_soft_rst
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/test_mode_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_data_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_data_oe_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_rwds_oe_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_q
add wave -noupdate -divider Hyp
add wave -noupdate -expand /hyperbus_tb/fix/hyper_cs_n_wire
add wave -noupdate /hyperbus_tb/fix/hyper_ck_wire
add wave -noupdate /hyperbus_tb/fix/hyper_ck_n_wire
add wave -noupdate /hyperbus_tb/fix/hyper_rwds_wire
add wave -noupdate -expand /hyperbus_tb/fix/hyper_dq_wire
add wave -noupdate /hyperbus_tb/fix/hyper_reset_n_wire
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/timer_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2633315668 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 164
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
WaveRestoreZoom {149337674 ps} {151410375 ps}
