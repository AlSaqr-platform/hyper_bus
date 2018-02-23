// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// Description: single to double data rate converter

module ddr_out #(
    int unsigned INIT = 1'b0
)(
   input  logic rst_ni,
   input  logic clk0_i,
   input  logic clk1_i,
   input  logic en_i,
   input  logic d0_i,
   input  logic d1_i,
   output logic q_o,
);
    reg  q0;
    reg  q1;
    reg  sel0;
    reg  sel1;
    reg  sel;

    pulp_clock_mux2 ddrmux (
        .clk_o     ( q_o ),
        .clk0_i    ( q1  ),
        .clk1_i    ( q0  ),
        .clk_sel_i ( sel )
    );

    pulp_clock_xor2 ddrxor (
        .clk_o  ( sel  ),
        .clk0_i ( sel0 ),
        .clk1_i ( sel1 )
    );

    always @(posedge clk0_i or posedge rst_ni) begin
        if (~rst_ni) begin
            q0 <= INIT;
            q1 <= INIT;
            sel0 <= 0;
        end else if (en_i) begin
            q0 <= d0_i;
            q1 <= d1_i;
            sel0 <= ~sel0;
        end
    end

    always @(posedge clk1_i or posedge rst_ni) begin
        if (~rst_ni)
            sel1 <= 0;
        else if (en_i)
            sel1 <= ~sel1;
    end
endmodule // rpc2_ctrl_output_ddr
