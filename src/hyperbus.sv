// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// Author:
// Date:
// Description:
`timescale 1ps/1ps

module hyperbus #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2
)(
    input logic                    clk_i,          // Clock
    input logic                    rst_ni,         // Asynchronous reset active low

    REG_BUS.in                     cfg_i,
    AXI_BUS.in                     axi_i,
    // physical interface
    output logic [NR_CS-1:0]       hyper_cs_no,
    output logic                   hyper_ck_o,
    output logic                   hyper_ck_no,
    output logic                   hyper_rwds_o,
    input  logic                   hyper_rwds_i,
    output logic                   hyper_rwds_oe_o,
    input  logic [7:0]             hyper_dq_i,
    output logic [7:0]             hyper_dq_o,
    output logic                   hyper_dq_oe_o,
    output logic                   hyper_reset_no
);
    logic                          clk0;        //Clk for phy and FIFOS
    logic                          clk90;
    //TODO: cdc_fifo_gray for TX/RX from axi to phy
    logic                          axi_tx_valid_o;
    logic                          axi_tx_ready;
    logic [15:0]                   axi_tx_data;
    logic [1:0]                    axi_tx_strb;   // mask data
    // receiving channel
    logic                          axi_rx_valid;
    logic                          axi_rx_ready;
    logic [15:0]                   axi_rx_data;
    logic                          axi_rx_last;

    //Connecting phy to TX
    logic [15:0]                   phy_tx_data;
    logic [1:0]                    phy_tx_strb;
    logic [15:0]                   phy_rx_data;
    logic                          phy_rx_last;
    logic                          phy_rx_valid;
    logic                          phy_rx_ready;
    logic                          phy_tx_valid;
    logic                          phy_tx_ready;
 
    //Direct trans to phy
    logic                          trans_valid;
    logic                          trans_ready;
    logic [31:0]                   trans_address;
    logic [NR_CS-1:0]              trans_cs;        // chipselect
    logic                          trans_write;     // transaction is a write
    logic [BURST_WIDTH-1:0]        trans_burst;
    logic                          trans_burst_type;
    logic                          trans_address_space;
    logic                          trans_error;
    logic [15:0]                   config_cs_max;
    
    clk_gen ddr_clk (
        .clk_i    ( clk_i  ),
        .rst_ni   ( rst_ni ),
        .clk0_o   ( clk0   ),
        .clk90_o  ( clk90  ),
        .clk180_o (        ),
        .clk270_o (        )
    );

    hyperbus_axi hyperbus_axi_i (
        .clk_i                  ( clk_i                 ),
        .rst_ni                 ( rst_ni                ),
        .axi_i                  ( axi_i                 ),  

        .rx_data_i              ( axi_rx_data           ),
        .rx_last_i              ( axi_rx_last           ),
        .rx_valid_i             ( axi_rx_valid          ),
        .rx_ready_o             ( axi_rx_ready          ),

        .tx_data_o              ( axi_tx_data           ),
        .tx_strb_o              ( axi_tx_strb           ),
        .tx_valid_o             ( axi_tx_valid          ),
        .tx_ready_i             ( axi_tx_ready          ),

        .trans_valid_o          ( trans_valid           ),
        .trans_ready_i          ( trans_ready           ),
        .trans_address_o        ( trans_address         ),
        .trans_cs_o             ( trans_cs              ),
        .trans_write_o          ( trans_write           ),
        .trans_burst_o          ( trans_burst           ),
        .trans_burst_type_o     ( trans_burst_type      ),
        .trans_address_space_o  ( trans_address_space   ),
        .trans_error_i          ( trans_error           ),
        .config_cs_max_o        ( config_cs_max         )
    );

    hyperbus_phy hyperbus_phy_i (
        .clk0                         ( clk0                  ),
        .clk90                        ( clk90                 ),
        .rst_ni                       ( rst_ni                ),

        .config_t_latency_access      ( 32'h6                 ),
        .config_t_latency_additional  ( 32'h6                 ),
        .config_t_cs_max              ( 32'd666               ),
        .config_t_read_write_recovery ( 32'h6                 ),
        .config_t_rwds_delay_line     ( 32'd2000              ),

        .trans_valid_i                ( trans_valid           ),
        .trans_ready_o                ( trans_ready           ),
        .trans_address_i              ( trans_address         ),
        .trans_cs_i                   ( trans_cs              ),
        .trans_write_i                ( trans_write           ),
        .trans_burst_i                ( trans_burst           ),
        .trans_burst_type_i           ( trans_burst_type      ),
        .trans_address_space_i        ( trans_address_space   ),
        .trans_error_o                ( trans_error           ),

        .tx_valid_i                   ( phy_tx_valid          ),
        .tx_ready_o                   ( phy_tx_ready          ),
        .tx_data_i                    ( phy_tx_data           ),
        .tx_strb_i                    ( phy_tx_strb           ),

        .rx_valid_o                   ( phy_rx_valid          ),
        .rx_ready_i                   ( phy_rx_ready          ),
        .rx_data_o                    ( phy_rx_data           ),
        .rx_last_o                    ( phy_rx_last           ),

        .hyper_cs_no                  ( hyper_cs_no           ),
        .hyper_ck_o                   ( hyper_ck_o            ),
        .hyper_ck_no                  ( hyper_ck_no           ),
        .hyper_rwds_o                 ( hyper_rwds_o          ),
        .hyper_rwds_i                 ( hyper_rwds_i          ),
        .hyper_rwds_oe_o              ( hyper_rwds_oe_o       ),
        .hyper_dq_i                   ( hyper_dq_i            ),
        .hyper_dq_o                   ( hyper_dq_o            ),
        .hyper_dq_oe_o                ( hyper_dq_oe_o         ),
        .hyper_reset_no               ( hyper_reset_no        )
    );
    // TODO: Check if FSM is correct
    // TODO:     axi_i.b_valid, Write done

    //Write data, TX CDC FIFO
    cdc_fifo_gray  #(.T(logic[17:0]), .LOG_DEPTH(3)) i_cdc_TX_fifo ( 
        .src_rst_ni  ( rst_ni                     ),
        .src_clk_i   ( clk_i                      ),
        .src_data_i  ( {axi_tx_data, axi_tx_strb} ),
        .src_valid_i ( axi_tx_valid               ),
        .src_ready_o ( axi_tx_ready               ),
    
        .dst_rst_ni  ( rst_ni                     ),
        .dst_clk_i   ( clk0                       ),
        .dst_data_o  ( {phy_tx_data, phy_tx_strb} ),
        .dst_valid_o ( phy_tx_valid               ),
        .dst_ready_i ( phy_tx_ready               )
    ); 

    //Read data, RX CDC FIFO
    cdc_fifo_gray  #(.T(logic[16:0]), .LOG_DEPTH(3)) i_cdc_RX_fifo ( 
        .src_rst_ni  ( rst_ni                     ),
        .src_clk_i   ( clk0                       ),
        .src_data_i  ( {phy_rx_data, phy_rx_last} ),
        .src_valid_i ( phy_rx_valid               ),
        .src_ready_o ( phy_rx_ready               ),
    
        .dst_rst_ni  ( rst_ni                     ),
        .dst_clk_i   ( clk_i                      ),
        .dst_data_o  ( {axi_rx_data, axi_rx_last} ),
        .dst_valid_o ( axi_rx_valid               ),
        .dst_ready_i ( axi_rx_ready               )
    );   
endmodule
