onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/clk_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rst_ni
add wave -noupdate -divider AXI-side
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/chip_rules_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/addr_space_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/axi_req_i.aw_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/axi_rsp_o.aw_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/axi_req_i.ar_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/axi_rsp_o.ar_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/axi_req_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/axi_rsp_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/atop_out_req
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/atop_out_rsp
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.ar_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.ar_ready
add wave -noupdate -expand -subitemconfig {/hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.w -expand} /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req_aw
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req_ar
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rr_out_req_ax
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rr_out_req_write
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_ready_i
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_axi_slave/rx_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rx_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/tx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/lane_cnt_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/lane_cnt_endbeat
add wave -noupdate -divider {AXI W DOWN}
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.aw
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.aw_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.aw_ready
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.w
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.w_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.w_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.b
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.b_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.b_ready
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_axi_slave/tx_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/tx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/tx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/boffs_cnt_last
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/lane_boffs_q
add wave -noupdate -divider {AXI B UP}
add wave -noupdate -label b /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.b
add wave -noupdate -label b_valid /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_rsp.b_valid
add wave -noupdate -label b_ready /hyperbus_tb/fix/i_dut/i_axi_slave/ser_out_req.b_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/b_error_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/b_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/b_ready_o
add wave -noupdate -divider PHY-side
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/trans_cs_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/curr_ax_size_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/curr_ax_size_q
add wave -noupdate -expand /hyperbus_tb/fix/i_dut/i_axi_slave/rx_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rx_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/rx_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/r_data_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/r_data_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/r_error_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/r_error_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_axi_slave/chip_sel_idx
add wave -noupdate -divider TRX
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/clk_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rst_ni
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/test_mode_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/cs_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/cs_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rwds_sample_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_clk_delay_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_clk_ena_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_data_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_data_oe_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_rwds_oe_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_clk_delay_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_dq_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/NumChips
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/RxFifoLogDepth
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_clk_ena_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/tx_clk_90
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_90
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_clk_orig
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_soft_rst
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_fifo_in
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_fifo_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_rwds_fifo_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rwds_sample_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_data_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/rx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_cs_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_ck_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_ck_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_rwds_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_rwds_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_dq_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_dq_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/i_trx/hyper_reset_no
add wave -noupdate -divider PHY
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_error_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cfg_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/clk_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_dq_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_rwds_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rst_ni
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_ready_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/test_mode_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_cs_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_valid_i
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_ck_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_ck_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_cs_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_dq_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_dq_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_reset_no
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_rwds_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/hyper_rwds_oe_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/rx_valid_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trans_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tx_ready_o
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_clear
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/b_pending_set
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ca
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cs_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/cs_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_add_latency
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_rclk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_rcnt_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_tf_burst_done
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_tf_burst_last
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_one
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_rwr_done
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_two
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_timer_zero
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_wclk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/ctl_write_zero_lat
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/NumChips
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/r_outstand_dec
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/r_outstand_inc
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/r_outstand_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/RxFifoLogDepth
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/StartupCycles
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/state_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tf_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/tf_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/timer_d
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/timer_q
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/TimerWidth
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_clk_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_cs_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rwds_sample
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rwds_sample_ena
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_ready
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_rx_valid
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_data
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_data_oe
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_rwds
add wave -noupdate /hyperbus_tb/fix/i_dut/i_phy/trx_tx_rwds_oe
add wave -noupdate -divider PHYS
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
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {548263000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 167
configure wave -valuecolwidth 127
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
WaveRestoreZoom {548216494 ps} {548290347 ps}
