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

import axi_pkg::*;

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

    //REG_BUS.in                     cfg_i,
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

    hyperbus_axi #(.AXI_IW(AXI_IW)) axi2phy_ix (
        .clk_i                 ( clk_i                   ),
        .rst_ni                ( rst_ni                  ),
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
        .clk0                         ( clk0                  ),
        .clk90                        ( clk90                 ),
        .rst_ni                       ( rst_ni                ),

        .config_t_latency_access      ( 32'h6                 ),
        .config_t_latency_additional  ( 32'h6                 ),
        .config_t_cs_max              ( 32'd665               ),
        .config_t_read_write_recovery ( 32'h6                 ),
        .config_t_rwds_delay_line     ( 32'd2000              ),

        .trans_valid_i                ( phy_trans_valid         ),
        .trans_ready_o                ( phy_trans_ready         ),
        .trans_address_i              ( phy_trans.address       ),
        .trans_cs_i                   ( phy_trans.cs            ),
        .trans_write_i                ( phy_trans.write         ),
        .trans_burst_i                ( phy_trans.burst         ),
        .trans_burst_type_i           ( phy_trans.burst_type    ),
        .trans_address_space_i        ( phy_trans.address_space ),

        .tx_valid_i                   ( phy_tx_valid          ),
        .tx_ready_o                   ( phy_tx_ready          ),
        .tx_data_i                    ( phy_tx.data           ),
        .tx_strb_i                    ( phy_tx.strb           ),

        .rx_valid_o                   ( phy_rx_valid          ),
        .rx_ready_i                   ( phy_rx_ready          ),
        .rx_data_o                    ( phy_rx.data           ),
        .rx_error_o                   ( phy_rx.error          ),
        .rx_last_o                    ( phy_rx.last           ),

        .b_resp_valid_o               ( phy_b_valid           ),
        .b_last_o                     ( phy_b_resp.last       ),
        .b_error_o                    ( phy_b_resp.error      ),

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
        .dst_valid_o (             ),
        .dst_ready_i ( 1'b1        )
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


module hyperbus_inflate #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2,
    parameter AXI_AW = 32,
    parameter AXI_UW = 0,
    parameter AXI_IW = 10
)(
`ifdef FPGA
    input  logic                   clk0,    // Clock
    input  logic                   clk90,    // Clock
`else
    input  logic                   clk_i,
`endif
    input logic                    rst_ni,         // Asynchronous reset active low

    //REG_BUS.in                     cfg_i,

    input  logic [AXI_IW-1:0]      axi_i_aw_id,
    input  logic [AXI_AW-1:0]      axi_i_aw_addr,
    input  logic [7:0]             axi_i_aw_len,
    input  logic [2:0]             axi_i_aw_size,
    input  burst_t                 axi_i_aw_burst,
    input  logic                   axi_i_aw_lock,
    input  cache_t                 axi_i_aw_cache,
    input  prot_t                  axi_i_aw_prot,
    input  qos_t                   axi_i_aw_qos,
    input  region_t                axi_i_aw_region,
    input  logic [AXI_UW-1:0]      axi_i_aw_user,
    input  logic                   axi_i_aw_valid,
    output logic                   axi_i_aw_ready,

    input  logic [15:0]            axi_i_w_data,
    input  logic [1:0]             axi_i_w_strb,
    input  logic                   axi_i_w_last,
    input  logic [AXI_UW-1:0]      axi_i_w_user,
    input  logic                   axi_i_w_valid,
    output logic                   axi_i_w_ready,

    output logic [AXI_IW-1:0]      axi_i_b_id,
    output resp_t                  axi_i_b_resp,
    output logic [AXI_UW-1:0]      axi_i_b_user,
    output logic                   axi_i_b_valid,
    input  logic                   axi_i_b_ready,

    input  logic [AXI_IW-1:0]      axi_i_ar_id,
    input  logic [AXI_AW-1:0]      axi_i_ar_addr,
    input  logic [7:0]             axi_i_ar_len,
    input  logic [2:0]             axi_i_ar_size,
    input  burst_t                 axi_i_ar_burst,
    input  logic                   axi_i_ar_lock,
    input  cache_t                 axi_i_ar_cache,
    input  prot_t                  axi_i_ar_prot,
    input  qos_t                   axi_i_ar_qos,
    input  region_t                axi_i_ar_region,
    input  logic [AXI_UW-1:0]      axi_i_ar_user,
    input  logic                   axi_i_ar_valid,
    output logic                   axi_i_ar_ready,

    output logic [AXI_IW-1:0]      axi_i_r_id,
    output logic [15:0]            axi_i_r_data,
    output resp_t                  axi_i_r_resp,
    output logic                   axi_i_r_last,
    output logic [AXI_UW-1:0]      axi_i_r_user,
    output logic                   axi_i_r_valid,
    input  logic                   axi_i_r_ready,

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

    AXI_BUS #(
        .AXI_ADDR_WIDTH    ( AXI_AW ),
        .AXI_DATA_WIDTH    ( 16     ),
        .AXI_ID_WIDTH      ( AXI_IW ),
        .AXI_USER_WIDTH    ( AXI_UW )
    ) axi_i (clk_i);

    assign axi_i.aw_id     = axi_i_aw_id;
    assign axi_i.aw_addr   = axi_i_aw_addr;
    assign axi_i.aw_len    = axi_i_aw_len;
    assign axi_i.aw_size   = axi_i_aw_size;
    assign axi_i.aw_burst  = axi_i_aw_burst;
    assign axi_i.aw_lock   = axi_i_aw_lock;
    assign axi_i.aw_cache  = axi_i_aw_cache;
    assign axi_i.aw_prot   = axi_i_aw_prot;
    assign axi_i.aw_qos    = axi_i_aw_qos;
    assign axi_i.aw_region = axi_i_aw_region;
    assign axi_i.aw_user   = axi_i_aw_user;
    assign axi_i.aw_valid  = axi_i_aw_valid;
    assign axi_i_aw_ready  = axi_i.aw_ready;

    assign axi_i.w_data    = axi_i_w_data;
    assign axi_i.w_strb    = axi_i_w_strb;
    assign axi_i.w_last    = axi_i_w_last;
    assign axi_i.w_user    = axi_i_w_user;
    assign axi_i.w_valid   = axi_i_w_valid;
    assign axi_i_w_ready   = axi_i.w_ready;

    assign axi_i_b_id      = axi_i.b_id;
    assign axi_i_b_resp    = axi_i.b_resp;
    assign axi_i_b_user    = axi_i.b_user;
    assign axi_i_b_valid   = axi_i.b_valid;
    assign axi_i.b_ready   = axi_i_b_ready;

    assign axi_i.ar_id     = axi_i_ar_id;
    assign axi_i.ar_addr   = axi_i_ar_addr;
    assign axi_i.ar_len    = axi_i_ar_len;
    assign axi_i.ar_size   = axi_i_ar_size;
    assign axi_i.ar_burst  = axi_i_ar_burst;
    assign axi_i.ar_lock   = axi_i_ar_lock;
    assign axi_i.ar_cache  = axi_i_ar_cache;
    assign axi_i.ar_prot   = axi_i_ar_prot;
    assign axi_i.ar_qos    = axi_i_ar_qos;
    assign axi_i.ar_region = axi_i_ar_region;
    assign axi_i.ar_user   = axi_i_ar_user;
    assign axi_i.ar_valid  = axi_i_ar_valid;
    assign axi_i_ar_ready  = axi_i.ar_ready;

    assign axi_i_r_id      = axi_i.r_id;
    assign axi_i_r_data    = axi_i.r_data;
    assign axi_i_r_resp    = axi_i.r_resp;
    assign axi_i_r_last    = axi_i.r_last;
    assign axi_i_r_user    = axi_i.r_user;
    assign axi_i_r_valid   = axi_i.r_valid;
    assign axi_i.r_ready   = axi_i_r_ready;


    hyperbus #(
        .BURST_WIDTH ( BURST_WIDTH ),
        .NR_CS       ( NR_CS       ),
        .AXI_IW      ( AXI_IW      )
    ) i_deflate (
        .clk_i           ( clk_i           ),
        .rst_ni          ( rst_ni          ),         // Asynchronous reset active low

        .axi_i           ( axi_i           ),

        .hyper_cs_no     ( hyper_cs_no     ),
        .hyper_ck_o      ( hyper_ck_o      ),
        .hyper_ck_no     ( hyper_ck_no     ),
        .hyper_rwds_o    ( hyper_rwds_o    ),
        .hyper_rwds_i    ( hyper_rwds_i    ),
        .hyper_rwds_oe_o ( hyper_rwds_oe_o ),
        .hyper_dq_i      ( hyper_dq_i      ),
        .hyper_dq_o      ( hyper_dq_o      ),
        .hyper_dq_oe_o   ( hyper_dq_oe_o   ),
        .hyper_reset_no  ( hyper_reset_no  )
    );

endmodule


module hyperbus_deflate #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2,
    parameter AXI_AW = 32,
    parameter AXI_UW = 0,
    parameter AXI_IW = 10
)(
`ifdef FPGA
    input  logic                   clk0,    // Clock
    input  logic                   clk90,    // Clock
`else
    input  logic                   clk_i,
`endif
    input logic                    rst_ni,         // Asynchronous reset active low

    //REG_BUS.in                     cfg_i,
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

    hyperbus_inflate #(
        .BURST_WIDTH ( BURST_WIDTH ),
        .NR_CS       ( NR_CS       ),
        .AXI_AW      ( AXI_AW      ),
        .AXI_UW      ( AXI_UW      ),
        .AXI_IW      ( AXI_IW      )
    ) i_inflate (
    `ifdef FPGA
        .clk0            ( clk0            ),    // Clock
        .clk90           ( clk90           ),    // Clock
    `else
        .clk_i           ( clk_i           ),
    `endif
        .rst_ni          ( rst_ni          ),         // Asynchronous reset active low

        .axi_i_aw_id     ( axi_i.aw_id     ),
        .axi_i_aw_addr   ( axi_i.aw_addr   ),
        .axi_i_aw_len    ( axi_i.aw_len    ),
        .axi_i_aw_size   ( axi_i.aw_size   ),
        .axi_i_aw_burst  ( axi_i.aw_burst  ),
        .axi_i_aw_lock   ( axi_i.aw_lock   ),
        .axi_i_aw_cache  ( axi_i.aw_cache  ),
        .axi_i_aw_prot   ( axi_i.aw_prot   ),
        .axi_i_aw_qos    ( axi_i.aw_qos    ),
        .axi_i_aw_region ( axi_i.aw_region ),
        .axi_i_aw_user   ( axi_i.aw_user   ),
        .axi_i_aw_valid  ( axi_i.aw_valid  ),
        .axi_i_aw_ready  ( axi_i.aw_ready  ),

        .axi_i_w_data    ( axi_i.w_data    ),
        .axi_i_w_strb    ( axi_i.w_strb    ),
        .axi_i_w_last    ( axi_i.w_last    ),
        .axi_i_w_user    ( axi_i.w_user    ),
        .axi_i_w_valid   ( axi_i.w_valid   ),
        .axi_i_w_ready   ( axi_i.w_ready   ),

        .axi_i_b_id      ( axi_i.b_id      ),
        .axi_i_b_resp    ( axi_i.b_resp    ),
        .axi_i_b_user    ( axi_i.b_user    ),
        .axi_i_b_valid   ( axi_i.b_valid   ),
        .axi_i_b_ready   ( axi_i.b_ready   ),

        .axi_i_ar_id     ( axi_i.ar_id     ),
        .axi_i_ar_addr   ( axi_i.ar_addr   ),
        .axi_i_ar_len    ( axi_i.ar_len    ),
        .axi_i_ar_size   ( axi_i.ar_size   ),
        .axi_i_ar_burst  ( axi_i.ar_burst  ),
        .axi_i_ar_lock   ( axi_i.ar_lock   ),
        .axi_i_ar_cache  ( axi_i.ar_cache  ),
        .axi_i_ar_prot   ( axi_i.ar_prot   ),
        .axi_i_ar_qos    ( axi_i.ar_qos    ),
        .axi_i_ar_region ( axi_i.ar_region ),
        .axi_i_ar_user   ( axi_i.ar_user   ),
        .axi_i_ar_valid  ( axi_i.ar_valid  ),
        .axi_i_ar_ready  ( axi_i.ar_ready  ),

        .axi_i_r_id      ( axi_i.r_id      ),
        .axi_i_r_data    ( axi_i.r_data    ),
        .axi_i_r_resp    ( axi_i.r_resp    ),
        .axi_i_r_last    ( axi_i.r_last    ),
        .axi_i_r_user    ( axi_i.r_user    ),
        .axi_i_r_valid   ( axi_i.r_valid   ),
        .axi_i_r_ready   ( axi_i.r_ready   ),

        // physical interface
        .hyper_cs_no     ( hyper_cs_no     ),
        .hyper_ck_o      ( hyper_ck_o      ),
        .hyper_ck_no     ( hyper_ck_no     ),
        .hyper_rwds_o    ( hyper_rwds_o    ),
        .hyper_rwds_i    ( hyper_rwds_i    ),
        .hyper_rwds_oe_o ( hyper_rwds_oe_o ),
        .hyper_dq_i      ( hyper_dq_i      ),
        .hyper_dq_o      ( hyper_dq_o      ),
        .hyper_dq_oe_o   ( hyper_dq_oe_o   ),
        .hyper_reset_no  ( hyper_reset_no  )
    );

endmodule
