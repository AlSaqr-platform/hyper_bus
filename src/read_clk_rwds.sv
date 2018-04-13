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
// Description: Connection between HyperBus and Read CDC FIFO
`timescale 1 ps/1 ps

module read_clk_rwds #(
)(
    input logic                    clk0,
    input logic                    rst_ni,   // Asynchronous reset active low

    input logic [31:0]             config_t_rwds_delay_line,

    input logic                    hyper_rwds_i,
    input logic [7:0]              hyper_dq_i,
    input logic                    read_clk_en_i,
    input logic                    en_ddr_in_i,
    input logic                    ready_i, //Clock to FIFO

    output logic                   valid_o,
    output logic [15:0]            data_o
);

    logic hyper_rwds_i_d;
    logic clk_rwds;

    assign #(config_t_rwds_delay_line) hyper_rwds_i_d = hyper_rwds_i; //Delay of rwds for center aligned read

    logic cdc_input_fifo_ready;
    logic read_in_valid;
    logic [15:0] src_data;

    cdc_fifo_gray  #(.T(logic[15:0]), .LOG_DEPTH(3)) i_cdc_fifo_hyper ( 
      .src_rst_ni  ( rst_ni               ), 
      .src_clk_i   ( clk_rwds             ), 
      .src_data_i  ( src_data             ), 
      .src_valid_i ( read_in_valid        ), 
      .src_ready_o ( cdc_input_fifo_ready ), 
 
      .dst_rst_ni  ( rst_ni  ), 
      .dst_clk_i   ( clk0    ), 
      .dst_data_o  ( data_o  ), 
      .dst_valid_o ( valid_o ), 
      .dst_ready_i ( ready_i ) 
    ); 

    `ifndef SYNTHESIS
    always @(negedge cdc_input_fifo_ready) begin
        assert(cdc_input_fifo_ready) else $error("FIFO i_cdc_fifo_hyper should always be ready");
    end
    `endif

    logic resetReadModule;
    assign resetReadModule = ~rst_ni || ~read_clk_en_i; //todo: second async reset!!!! okay?

    always_ff @(posedge clk_rwds or posedge resetReadModule) begin : proc_read_in_valid
        if(resetReadModule) begin
            read_in_valid <= 0;
        end else begin
            read_in_valid <= 1;
        end
    end

    //Takes 8 bit ddr data from hyperram to 16 bit
    ddr_in i_ddr_in (
        .clk_i  ( clk_rwds    ), 
        .rst_ni ( rst_ni      ),
        .data_i ( hyper_dq_i  ), 
        .enable ( en_ddr_in_i ),
        .data_o ( src_data    ) 
    ); 

    //Clock gating resulting in clk_rwds
    pulp_clock_gating cdc_read_ck_gating (
        .clk_i      ( hyper_rwds_i_d ),
        .en_i       ( read_clk_en_i  ),
        .test_en_i  ( 1'b0           ),
        .clk_o      ( clk_rwds       )
    );

endmodule
