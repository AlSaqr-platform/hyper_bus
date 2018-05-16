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
    parameter NR_CS = 2,
    parameter AXI_IW = 10
)(
`ifdef FPGA
    input  logic                   clk0,    // Clock
    input  logic                   clk90,    // Clock
`else
    input  logic                   clk_i,
`endif
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

    //FGPA uses global clocking with MMCM
`ifdef FPGA
    logic clk_i;
    assign clk_i = clk0;
`else
    logic clk0;   //Clk for phy and FIFOS 
    logic clk90;

    clk_gen ddr_clk (
        .clk_i    ( clk_i  ),
        .rst_ni   ( rst_ni ),
        .clk0_o   ( clk0   ),
        .clk90_o  ( clk90  ),
        .clk180_o (        ),
        .clk270_o (        )
    );
`endif
    
    logic [31:0]                   config_t_latency_access;
    logic [31:0]                   config_t_latency_additional;
    logic [31:0]                   config_t_cs_max;
    logic [31:0]                   config_t_read_write_recovery;
    logic [31:0]                   config_t_rwds_delay_line;
    logic [NR_CS*64-1:0]           config_addr_mapping;

    //TODO: cdc_fifo_gray for TX/RX from axi to phy
    logic                          axi_tx_valid;
    logic                          axi_tx_ready;

    // receiving channel
    logic                          axi_rx_valid;
    logic                          axi_rx_ready;
    logic [15:0]                   axi_rx_data;
    logic                          axi_rx_last;
    logic                          axi_rx_error;

    //Connecting phy to TX
    logic                          phy_tx_valid;
    logic                          phy_tx_ready;

    logic                          phy_rx_valid;
    logic                          phy_rx_ready;
 
    //Direct trans to phy
    logic                          axi_trans_valid;
    logic                          axi_trans_ready;                    

    logic                          phy_trans_valid;
    logic                          phy_trans_ready;

    logic                          phy_b_last;
    logic                          phy_b_valid;
    logic                          phy_b_error;

    logic                          axi_tx_error;
    logic                          axi_tx_last;

    logic                          axi_b_valid;
    logic                          axi_b_ready;
    typedef struct packed{ 
        logic [NR_CS-1:0]          cs;        // chipselect
        logic                      write;     // transaction is a write
        logic [BURST_WIDTH-1:0]    burst;
        logic                      burst_type;
        logic                      address_space;
        logic [31:0]               address;
    }trans_struct;

    typedef struct packed{ 
        logic [15:0]               data;
        logic [1:0]                strb;   // mask data
    }tx_data;

    typedef struct packed {
        logic                      last;
        logic                      error;
        logic [15:0]               data;
    }rx_data;

    typedef struct packed{
        logic                      last;
        logic                      error;
    }b_resp;

    trans_struct axi_trans;
    trans_struct phy_trans;

    tx_data     axi_tx;
    tx_data     phy_tx;

    rx_data     axi_rx;
    rx_data     phy_rx;

    b_resp      axi_b_resp;
    b_resp      phy_b_resp;


    config_registers config_registers_i (
        .clk_i                        ( clk_i                        ),
        .rst_ni                       ( rst_ni                       ),

        .cfg_i                        ( cfg_i                        ),

        .config_t_latency_access      ( config_t_latency_access      ),
        .config_t_latency_additional  ( config_t_latency_additional  ),
        .config_t_cs_max              ( config_t_cs_max              ),
        .config_t_read_write_recovery ( config_t_read_write_recovery ),
        .config_t_rwds_delay_line     ( config_t_rwds_delay_line     ),
        .config_addr_mapping          ( config_addr_mapping          )
    );

    hyperbus_axi #(.AXI_IW(AXI_IW)) axi2phy_i (
        .clk_i                 ( clk_i                   ),
        .rst_ni                ( rst_ni                  ),

        .config_addr_mapping   ( config_addr_mapping     ),

        .axi_i                 ( axi_i                   ),  

        .rx_data_i             ( axi_rx.data             ),
        .rx_last_i             ( axi_rx.last             ),
        .rx_error_i            ( axi_rx.error            ),
        .rx_valid_i            ( axi_rx_valid            ),
        .rx_ready_o            ( axi_rx_ready            ),

        .tx_data_o             ( axi_tx.data             ),
        .tx_strb_o             ( axi_tx.strb             ),
        .tx_valid_o            ( axi_tx_valid            ),
        .tx_ready_i            ( axi_tx_ready            ),

        .b_valid_i             ( axi_b_valid             ),
        .b_ready_o             ( axi_b_ready             ),
        .b_last_i              ( axi_b_resp.last         ),
        .b_error_i             ( axi_b_resp.error        ),

        .trans_valid_o         ( axi_trans_valid         ),
        .trans_ready_i         ( axi_trans_ready         ),
        .trans_address_o       ( axi_trans.address       ),
        .trans_cs_o            ( axi_trans.cs            ),
        .trans_write_o         ( axi_trans.write         ),
        .trans_burst_o         ( axi_trans.burst         ),
        .trans_burst_type_o    ( axi_trans.burst_type    ),
        .trans_address_space_o ( axi_trans.address_space )
    );

    hyperbus_phy phy_i (
        .clk0                         ( clk0                         ),
        .clk90                        ( clk90                        ),
        .rst_ni                       ( rst_ni                       ),

        .config_t_latency_access      ( config_t_latency_access      ),
        .config_t_latency_additional  ( config_t_latency_additional  ),
        .config_t_cs_max              ( config_t_cs_max              ),
        .config_t_read_write_recovery ( config_t_read_write_recovery ),
        .config_t_rwds_delay_line     ( config_t_rwds_delay_line     ),

        .trans_valid_i                ( phy_trans_valid              ),
        .trans_ready_o                ( phy_trans_ready              ),
        .trans_address_i              ( phy_trans.address            ),
        .trans_cs_i                   ( phy_trans.cs                 ),
        .trans_write_i                ( phy_trans.write              ),
        .trans_burst_i                ( phy_trans.burst              ),
        .trans_burst_type_i           ( phy_trans.burst_type         ),
        .trans_address_space_i        ( phy_trans.address_space      ),

        .tx_valid_i                   ( phy_tx_valid                 ),
        .tx_ready_o                   ( phy_tx_ready                 ),
        .tx_data_i                    ( phy_tx.data                  ),
        .tx_strb_i                    ( phy_tx.strb                  ),

        .rx_valid_o                   ( phy_rx_valid                 ),
        .rx_ready_i                   ( phy_rx_ready                 ),
        .rx_data_o                    ( phy_rx.data                  ),
        .rx_error_o                   ( phy_rx.error                 ),
        .rx_last_o                    ( phy_rx.last                  ),

        .b_resp_valid_o               ( phy_b_valid                  ),
        .b_last_o                     ( phy_b_resp.last              ),
        .b_error_o                    ( phy_b_resp.error             ),

        .hyper_cs_no                  ( hyper_cs_no                  ),
        .hyper_ck_o                   ( hyper_ck_o                   ),
        .hyper_ck_no                  ( hyper_ck_no                  ),
        .hyper_rwds_o                 ( hyper_rwds_o                 ),
        .hyper_rwds_i                 ( hyper_rwds_i                 ),
        .hyper_rwds_oe_o              ( hyper_rwds_oe_o              ),
        .hyper_dq_i                   ( hyper_dq_i                   ),
        .hyper_dq_o                   ( hyper_dq_o                   ),
        .hyper_dq_oe_o                ( hyper_dq_oe_o                ),
        .hyper_reset_no               ( hyper_reset_no               )
    );

    cdc_2phase #(.T(trans_struct)) i_cdc_2phase_trans_signals (
        .src_rst_ni  ( rst_ni          ),
        .src_clk_i   ( clk_i           ),
        .src_data_i  ( axi_trans       ),
        .src_valid_i ( axi_trans_valid ),
        .src_ready_o ( axi_trans_ready ),

        .dst_rst_ni  ( rst_ni          ),
        .dst_clk_i   ( clk0            ),
        .dst_data_o  ( phy_trans       ),
        .dst_valid_o ( phy_trans_valid ),
        .dst_ready_i ( phy_trans_ready )
    );

    cdc_2phase #(.T(b_resp)) i_cdc_2phase_b_resp (
        .src_rst_ni  ( rst_ni      ),
        .src_clk_i   ( clk0        ),
        .src_data_i  ( phy_b_resp  ),
        .src_valid_i ( phy_b_valid ),
        .src_ready_o (             ),

        .dst_rst_ni  ( rst_ni      ),
        .dst_clk_i   ( clk_i       ),
        .dst_data_o  ( axi_b_resp  ),
        .dst_valid_o ( axi_b_valid ),
        .dst_ready_i ( axi_b_ready )
    );

    //Write data, TX CDC FIFO
    cdc_fifo_gray  #(.T(tx_data), .LOG_DEPTH(2)) i_cdc_TX_fifo ( 
        .src_rst_ni  ( rst_ni       ),
        .src_clk_i   ( clk_i        ),
        .src_data_i  ( axi_tx       ),
        .src_valid_i ( axi_tx_valid ),
        .src_ready_o ( axi_tx_ready ),
    
        .dst_rst_ni  ( rst_ni       ),
        .dst_clk_i   ( clk0         ),
        .dst_data_o  ( phy_tx       ),
        .dst_valid_o ( phy_tx_valid ),
        .dst_ready_i ( phy_tx_ready )
    ); 

    //Read data, RX CDC FIFO
    cdc_fifo_gray  #(.T(rx_data), .LOG_DEPTH(2)) i_cdc_RX_fifo ( 
        .src_rst_ni  ( rst_ni       ),
        .src_clk_i   ( clk0         ),
        .src_data_i  ( phy_rx       ),
        .src_valid_i ( phy_rx_valid ),
        .src_ready_o ( phy_rx_ready ),
    
        .dst_rst_ni  ( rst_ni       ),  
        .dst_clk_i   ( clk_i        ),  
        .dst_data_o  ( axi_rx       ),
        .dst_valid_o ( axi_rx_valid ),  
        .dst_ready_i ( axi_rx_ready )
    );   
endmodule
