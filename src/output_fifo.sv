// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

`timescale 1 ps/1 ps

module output_fifo #(
    int unsigned FIFO_SIZE = 4,
    int unsigned DATA_WIDTH = 18,
    int unsigned TOTAL_SIZE = FIFO_SIZE * DATA_WIDTH
)(
    input logic         clk_i,
    input logic         rst_ni,

    //IN Interface
    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic        valid_i,
    output logic        ready_o,

    //OUT Interface
    output logic [DATA_WIDTH-1:0] data_o,
    output logic        request_wait_o,
    input  logic        en_read_i
);


    logic [FIFO_SIZE-1:0] valid;

    logic [TOTAL_SIZE-1:0] storage;

    logic [1:0] sel_read; //ToDo depends on FIFO_SIZE

    logic [1:0] sel_write; 

    assign data_o = storage[DATA_WIDTH*sel_read+DATA_WIDTH-1-:DATA_WIDTH];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_storage
        if(~rst_ni) begin
            storage <= {TOTAL_SIZE{1'b0}};
            valid <= {FIFO_SIZE{1'b0}};
            sel_read <= '0;
            sel_write <= '0;
        end else  begin 

            //write to fifo
            if(valid_i && ~valid[sel_write]) begin
                storage[(DATA_WIDTH*sel_write)+DATA_WIDTH-1-:DATA_WIDTH] <= data_i;
                valid[sel_write] <= 1'b1;
                sel_write <= sel_write + 1;
            end

            //read from fifo
            if(en_read_i && valid[sel_read]) begin
                valid[sel_read] = 1'b0;
                sel_read <= sel_read + 1;
            end
        end
    end

    assign ready_o = ~valid[sel_write];

    assign request_wait_o = (valid == 4'b0000);

endmodule
