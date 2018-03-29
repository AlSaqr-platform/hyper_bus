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
// Description: Generate the Command-Address to start a transaction

module ddr_in #(
)(
	input logic 			 hyper_rwds_i_d,
	input logic  [7:0]       hyper_dq_i,
	input logic 			 rst_ni,
	input logic 			 enable,
	
	output logic [15:0]      data_o
);
	logic [7:0] ddr_neg;
	logic [7:0] ddr_pos;

    always_ff @(posedge hyper_rwds_i_d or negedge rst_ni) begin : proc_ddr_pos
        if(~rst_ni) begin
            ddr_pos <= 8'h0;
        end else if (enable) begin
            ddr_pos <= hyper_dq_i;
        end
    end
    
    always_ff @(negedge hyper_rwds_i_d or negedge rst_ni) begin : proc_ddr_neg
        if(~rst_ni) begin
            ddr_neg <= 8'h0;
        end else if (enable) begin
            ddr_neg <= hyper_dq_i;
        end
    end

    assign data_o[7:0]  = ddr_neg;
    assign data_o[15:8] = ddr_pos;

    // always_ff @(posedge hyper_rwds_i_d or negedge rst_ni) begin : proc_data_i //not on clk0, delayed rwds
    //     if(~rst_ni) begin
    //         data_o <= 16'h0;
    //     end else if (enable) begin
    //         data_o[7:0]  <= ddr_neg;
    //         data_o[15:8] <= ddr_pos;
    //     end
    // end
endmodule

