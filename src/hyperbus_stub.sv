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

endmodule