onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Chip
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/RWDS
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ7
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ6
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ5
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ4
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ3
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ2
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ1
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/DQ0
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/RESETNeg
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/CSNeg
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/CKNeg
add wave -noupdate /hyperbus_tb/fix/i_s27ks0641/CK
add wave -noupdate -divider TRX
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_in_delayed
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk_orig
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_soft_rst
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_data_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_fifo_ready
add wave -noupdate -divider {TRX IO}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_data_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_valid_o
add wave -noupdate -divider {PHY IO}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/clk_0_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/clk_90_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rst_ni
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/clk_test_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/test_mode_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cfg_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_cs_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_dq_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_error_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_cs_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_ck_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_ck_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_rwds_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_rwds_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_dq_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_dq_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_reset_no
add wave -noupdate -divider {PHY Internal}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/timer_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/timer_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tf_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tf_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cs_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cs_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_set
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_clear
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_write_zero_lat
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_add_latency
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_tx_burst_last
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_tf_burst_last
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_tf_burst_done
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_two
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_one
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_zero
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_rwr_done
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ca
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ca_tx_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_cs_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rwds_sample
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rwds_sample_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_data_oe
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_rwds
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_rwds_oe
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {150667549 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {150588794 ps} {150789193 ps}
