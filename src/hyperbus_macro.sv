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

module hyperbus_macro #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2,
    parameter AXI_IW = 10
)(
    input  logic                   clk_phy_i,
    input  logic                   clk_sys_i,
    input logic                    rst_ni,

    REG_BUS.in                     cfg_i,
    AXI_BUS.in                     axi_i,

    // physical interface
    output logic                   hyper_reset_no,
    output logic [NR_CS-1:0]       hyper_cs_no,
    inout  wire                    hyper_ck_o,    //With Pad
    inout  wire                    hyper_ck_no,   //With Pad
    inout  wire                    hyper_rwds_io, //With Pad
    inout  wire [7:0]              hyper_dq_io    //With Pad
);

    logic       hyper_ck_o_inner;
    logic       hyper_ck_no_inner;
    logic       hyper_rwds_o;
    logic       hyper_rwds_i;
    logic       hyper_rwds_oe_o;
    logic [7:0] hyper_dq_i;
    logic [7:0] hyper_dq_o;
    logic       hyper_dq_oe_o;

  IUMB pad_hyper_ck_no (
    .DO(hyper_ck_no_inner),
    .DI(),
    .PAD(hyper_ck_no),
    .OE(1'b1),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_ck_o (
    .DO(hyper_ck_o_inner),
    .DI(),
    .PAD(hyper_ck_o),
    .OE(1'b1),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_rwds_io (
    .DO(hyper_rwds_o),
    .DI(hyper_rwds_i),
    .PAD(hyper_rwds_io),
    .OE(hyper_rwds_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_0 (
    .DO(hyper_dq_o[0]),
    .DI(hyper_dq_i[0]),
    .PAD(hyper_dq_io[0]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_1 (
    .DO(hyper_dq_o[1]),
    .DI(hyper_dq_i[1]),
    .PAD(hyper_dq_io[1]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_2 (
    .DO(hyper_dq_o[2]),
    .DI(hyper_dq_i[2]),
    .PAD(hyper_dq_io[2]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_3 (
    .DO(hyper_dq_o[3]),
    .DI(hyper_dq_i[3]),
    .PAD(hyper_dq_io[3]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_4 (
    .DO(hyper_dq_o[4]),
    .DI(hyper_dq_i[4]),
    .PAD(hyper_dq_io[4]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_5 (
    .DO(hyper_dq_o[5]),
    .DI(hyper_dq_i[5]),
    .PAD(hyper_dq_io[5]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_6 (
    .DO(hyper_dq_o[6]),
    .DI(hyper_dq_i[6]),
    .PAD(hyper_dq_io[6]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_7 (
    .DO(hyper_dq_o[7]),
    .DI(hyper_dq_i[7]),
    .PAD(hyper_dq_io[7]),
    .OE(hyper_dq_oe_o),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

    hyperbus #(
        .BURST_WIDTH ( BURST_WIDTH ),
        .NR_CS       ( NR_CS       ),
        .AXI_IW      ( AXI_IW      )
    ) i_hyperbus (
        .clk_phy_i       ( clk_phy_i         ),
        .clk_sys_i       ( clk_sys_i         ),
        .rst_ni          ( rst_ni            ),
        .cfg_i           ( cfg_i             ),
        .axi_i           ( axi_i             ),
        .hyper_cs_no     ( hyper_cs_no       ),
        .hyper_ck_o      ( hyper_ck_o_inner  ),
        .hyper_ck_no     ( hyper_ck_no_inner ),
        .hyper_rwds_o    ( hyper_rwds_o      ),
        .hyper_rwds_i    ( hyper_rwds_i      ),
        .hyper_rwds_oe_o ( hyper_rwds_oe_o   ),
        .hyper_dq_i      ( hyper_dq_i        ),
        .hyper_dq_o      ( hyper_dq_o        ),
        .hyper_dq_oe_o   ( hyper_dq_oe_o     ),
        .hyper_reset_no  ( hyper_reset_no    )
    );

endmodule


module hyperbus_macro_inflate #(
    parameter BURST_WIDTH = 9,
    parameter NR_CS = 2,
    parameter AXI_AW = 32,
    parameter AXI_UW = 1,
    parameter AXI_IW = 10
)(
    input  logic                   clk_phy_i,
    input  logic                   clk_sys_i,
    input logic                    rst_ni,         // Asynchronous reset active low

    input [31:0]                   cfg_i_addr,
    input                          cfg_i_write,
    input [31:0]                   cfg_i_wdata,
    input [3:0]                    cfg_i_wstrb,
    input                          cfg_i_valid,
    output [31:0]                  cfg_i_rdata,
    output                         cfg_i_error,
    output                         cfg_i_ready,

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
    output logic                   hyper_reset_no,
    output logic [NR_CS-1:0]       hyper_cs_no,
    output logic                   hyper_ck_o,    //With Pad
    output logic                   hyper_ck_no,   //With Pad
    inout  wire                    hyper_rwds_io, //With Pad
    inout  wire [7:0]              hyper_dq_io    //With Pad
);

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) cfg_i(clk_sys_i);

    assign cfg_i.addr  = cfg_i_addr;
    assign cfg_i.write = cfg_i_write;
    assign cfg_i.wdata = cfg_i_wdata;
    assign cfg_i.wstrb = cfg_i_wstrb;
    assign cfg_i.valid = cfg_i_valid;

    assign cfg_i_rdata = cfg_i.rdata;
    assign cfg_i_error = cfg_i.error;
    assign cfg_i_ready = cfg_i.ready;

    AXI_BUS #(
        .AXI_ADDR_WIDTH    ( AXI_AW ),
        .AXI_DATA_WIDTH    ( 16     ),
        .AXI_ID_WIDTH      ( AXI_IW ),
        .AXI_USER_WIDTH    ( AXI_UW )
    ) axi_i (clk_sys_i);

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


    hyperbus_macro #(
        .BURST_WIDTH ( BURST_WIDTH ),
        .NR_CS       ( NR_CS       ),
        .AXI_IW      ( AXI_IW      )
    ) i_deflate (
        .clk_phy_i       ( clk_phy_i       ),
        .clk_sys_i       ( clk_sys_i       ),
        .rst_ni          ( rst_ni          ),

        .axi_i           ( axi_i           ),
        .cfg_i           ( cfg_i           ),

        .hyper_reset_no ( hyper_reset_no ),
        .hyper_cs_no    ( hyper_cs_no    ),
        .hyper_ck_o     ( hyper_ck_o     ),
        .hyper_ck_no    ( hyper_ck_no    ),
        .hyper_rwds_io  ( hyper_rwds_io  ),
        .hyper_dq_io    ( hyper_dq_io    )
    );

endmodule


module hyperbus_macro_deflate #(
    parameter BURST_WIDTH = 9,
    parameter NR_CS = 2,
    parameter AXI_AW = 32,
    parameter AXI_UW = 1,
    parameter AXI_IW = 10
)(
    input  logic                   clk_phy_i,
    input  logic                   clk_sys_i,
    input logic                    rst_ni,         // Asynchronous reset active low

    REG_BUS.in                     cfg_i,
    AXI_BUS.in                     axi_i,

    // physical interface
    output logic                   hyper_reset_no,
    output logic [NR_CS-1:0]       hyper_cs_no,
    output logic                   hyper_ck_o,    //With Pad
    output logic                   hyper_ck_no,   //With Pad
    inout  wire                    hyper_rwds_io, //With Pad
    inout  wire [7:0]              hyper_dq_io    //With Pad
);

    hyperbus_macro_inflate #(
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
        .clk_phy_i       ( clk_phy_i       ),
        .clk_sys_i       ( clk_sys_i       ),
    `endif
        .rst_ni          ( rst_ni          ),         // Asynchronous reset active low

        .cfg_i_addr      ( cfg_i.addr      ),
        .cfg_i_write     ( cfg_i.write     ),
        .cfg_i_wdata     ( cfg_i.wdata     ),
        .cfg_i_wstrb     ( cfg_i.wstrb     ),
        .cfg_i_valid     ( cfg_i.valid     ),
        .cfg_i_rdata     ( cfg_i.rdata     ),
        .cfg_i_error     ( cfg_i.error     ),
        .cfg_i_ready     ( cfg_i.ready     ),

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
        .hyper_reset_no  ( hyper_reset_no ),
        .hyper_cs_no     ( hyper_cs_no    ),
        .hyper_ck_o      ( hyper_ck_o     ),
        .hyper_ck_no     ( hyper_ck_no    ),
        .hyper_rwds_io   ( hyper_rwds_io  ),
        .hyper_dq_io     ( hyper_dq_io    )
    );

endmodule
