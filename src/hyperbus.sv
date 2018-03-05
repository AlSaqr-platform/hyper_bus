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

module hyperbus #(
    int unsigned NR_CS = 2
)(
    input logic                    clk_i,          // Clock
    input logic                    rst_ni,         // Asynchronous reset active low
    // AXI Bus
    // ....
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

    logic d0_i;
    logic d1_i;
    logic q_o;

    assign d0_i = 0;
    assign d1_i = 1;

    logic clk0;
    logic clk90;
    logic clk180;
    logic clk270;

  clk_gen ddr_clk (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .clk0_o (clk0),
    .clk90_o (clk90),
    .clk180_o (clk180),
    .clk270_o (clk270)
  );
  
  genvar i;
  generate
    for(i=0; i<=7; i++)
    begin: ddr_out_bus
      ddr_out ddr_data (
        .rst_ni (rst_ni),
        .clk_i (clk90),
        .d0_i (hyper_),
        .d1_i (d1_i),
        .q_o (hyper_dq_o[i])
      );
    end
  endgenerate



  assign hyper_ck_o = clk0;
  assign hyper_ck_no = clk180;

endmodule
