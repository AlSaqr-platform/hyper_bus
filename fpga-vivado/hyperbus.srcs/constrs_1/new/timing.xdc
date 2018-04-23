set CLK_PERIOD 3

create_clock [get_ports clk_i] -period $CLK_PERIOD -name clk_i

#todo fix names of signals

create_generated_clock  -name clk0 -source [get_ports clk_i] -edges {1 3 5} [get_pins phy_i/ddr_clk/r_clk0_o_reg/Q]
#create_generated_clock -source [get_pins ddr_clk/clk0] -edges {1 2 3} -edge_shift [list [expr $CLK_PERIOD*0.5] [expr $CLK_PERIOD*0.5] [expr $CLK_PERIOD*0.5] ]  \
#                                                        [get_pins ddr_clk/clk90]
                                                        
create_generated_clock -name clk90 -source [get_ports clk_i] -edges {2 4 6} [get_pins phy_i/ddr_clk/r_clk90_o_reg/Q]                                              
#create_generated_clock -source [get_pins ddr_clk/clk0] -edges {1 2 3} -edge_shift {3 3 3} [get_pins ddr_clk/clk180]
#create_generated_clock -source [get_pins ddr_clk/clk0] -edges {1 2 3} -edge_shift {4.5 4.5 4.5} [get_pins ddr_clk/clk270]

create_clock [get_ports hyper_rwds_io] -period [expr $CLK_PERIOD *2]
create_generated_clock -name clk_rwds -source [get_ports hyper_rwds_io] -edges {1 2 3} -edge_shift {2 2 2} [get_pins phy_i/i_read_clk_rwds/cdc_read_ck_gating/clock_gating/O]

#set_max_delay -from [get_pins {phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_gray_q_reg[*]/C}] -to [get_pins {phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q_reg[*]/D}] 3.0
#set_max_delay -from [get_pins {i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_gray_q_reg[1]/C}] -to [get_pins {i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q_reg[1]/D}] 3.0
#set_max_delay -from [get_pins {i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_gray_q_reg[2]/C}] -to [get_pins {i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q_reg[2]/D}] 3.0

set_max_delay -from [get_pins {phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_rptr_gray_q_reg[*]/C}] -to [get_pins {phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q_reg[*]/D}] 3.0
#set_max_delay -from [get_pins i_read_clk_rwds/i_cdc_fifo_hyper/g_word[*].fifo_data_q_reg[*][*]/Q] -to [get_pins cdc_fifo to axi...] 3.0

set_max_delay -through [get_nets phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_gray_q[*]] 4.1
set_max_delay -through [get_nets phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_data_o[*]] 4.2
set_max_delay -from [get_pins {phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/src_wptr_bin_q_reg[3]/C}] -to [get_pins {phy_i/i_read_clk_rwds/i_cdc_fifo_hyper/dst_wptr_gray_q_reg[3]/D}] 4.3
set_max_delay -through [get_nets phy_i/i_read_clk_rwds/read_clk_en_i] 3.1
set_max_delay -from [get_ports hyper_rwds_io] -to [get_pins phy_i/hyper_rwds_i_syn_reg/D] 6.1

#needed as input is sampled with clk_rwds but output is clk0
set_false_path -from [get_ports hyper_rwds_io] -to [get_ports hyper_rwds_io]

# Setting input and output delays.
set_output_delay 0.4 -clock clk0 [get_ports hyper_dq_io*]
set_output_delay 0.4 -clock clk0 [get_ports hyper_cs_*]
set_output_delay 0.4 -clock clk0 [get_ports hyper_rwds_io]
set_output_delay 0.4 -clock clk90 [get_ports hyper_ck_*]
set_input_delay 0.4 -clock clk_rwds [get_ports hyper_dq_io[*]]
