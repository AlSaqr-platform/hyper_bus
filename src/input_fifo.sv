// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

`timescale 1 ps/1 ps

module input_fifo #(
    int unsigned FIFO_SIZE = 4,
    int unsigned TOTAL_SIZE = FIFO_SIZE * 16
)(
    input logic         clk_i,
    input logic         rst_ni,

    //IN Interface
    input  logic [15:0] data_i,
    input  logic        en_write_i,
    output logic        request_wait_o,

    //OUT Interface
    output logic [15:0] data_o,
    output logic        valid_o,
    input  logic        ready_i
);


    logic [FIFO_SIZE-1:0] valid;

    logic [TOTAL_SIZE-1:0] storage;

    logic [1:0] sel_read; //ToDo depends on FIFO_SIZE

    logic [1:0] sel_write; 

    assign data_o = storage[(sel_read << 4)+15-:16];
    assign valid_o = valid[sel_read];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_storage
        if(~rst_ni) begin
            storage <= {TOTAL_SIZE{1'b0}};
            valid <= {FIFO_SIZE{1'b0}};
            sel_read <= '0;
            sel_write <= '0;
        end else  begin 

            //read from fifo
            if(ready_i && valid[sel_read]) begin
                valid[sel_read] = 1'b0;
                sel_read <= sel_read + 1;
            end

            //write to fifo
            if(en_write_i && ~valid[sel_write]) begin
                storage[(16*sel_write)+15-:16] <= data_i;
                valid[sel_write] = 1'b1;
                sel_write <= sel_write + 1;
            end
        end
    end

    assign request_wait_o = ~(valid == 4'b0000 || valid == 4'b0001 || valid == 4'b0010 || valid == 4'b0100 || valid == 4'b1000);

endmodule