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
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2
)(
    input logic                    clk_i,          // Clock
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
    //TODO: cdc_fifo_gray for TX/RX from axi to phy
    logic                   tx_valid_o,
    logic                   tx_ready_i,
    logic [15:0]            tx_data_o,
    logic [1:0]             tx_strb_o,   // mask data
    // receiving channel
    logic                   rx_valid_i,
    logic                   rx_ready_o,
    logic [15:0]            rx_data_i,

    //Direct trans to phy
    logic                          trans_valid_o,
    logic                          trans_ready_i,
    logic [31:0]                   trans_address_o,
    logic [NR_CS-1:0]              trans_cs_o,        // chipselect
    logic                          trans_write_o,     // transaction is a write
    logic [BURST_WIDTH-1:0]        trans_burst_i,
    logic                          trans_burst_type_o,
    logic                          trans_address_space_o,
    logic                          trans_error_i,
    logic [15:0]                   config_cs_max_o,

    logic                          mode_write;
    logic [7:0]                    burst_length;
    
    //TODO: initialize phy and CDC FIFOs

    assign cfg_i.ready = 1'b1;

    //Write, TX CDC FIFO
    assign tx_data_o = axi_i.w_data; //Input to fifo
    assign tx_strb_o = mode_write ? ~axi_i.w_strb : 2'b0; //WSTRB HIGH, RWDS LOW -> valid
    assign tx_valid_o = axi_i.w_valid;
    assign axi_i.w_ready = tx_ready_i;

    //Read, RX CDC FIFO
    assign axi_i.r_valid = rx_valid_i;
    assign rx_ready_o = axi_i.r_ready;
    assign axi_i.r_data = rx_data_i;

    //Assign axi_i to trans data
    assign trans_write_o = mode_write;
    assign trans_address_o = mode_write ? axi_i.aw_addr : axi_i.ar_addr;
    assign trans_address_space_o = 1'b0; //Memory space
    assign trans_burst_o = mode_write ? axi_i.aw_len : axi_i.ar_len; //Burst length, there is also also burst size 2^0, ... , 2^7
    assign trans_burst_type_o = mode_write ? axi_i.aw_burst : axi_i.ar_burst

    typedef enum logic[3:0] {STANDBY, READY, READ, WRITE} hyper_axi;

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_hyper_axi_state
        if(~rst_ni) begin
            hyper_axi_state <= STANDBY;
        end 
        else begin
            case(hyper_axi_state)
                STANDBY: begin
                    if(trans_ready_i) begin
                        hyper_axi_state <= READY;
                    else begin
                        hyper_axi_state <= STANDBY;
                    end
                end
                READY: begin
                    if(axi_i.ar_valid) begin
                        hyper_axi_state <= READ_ADDRESS;
                    end
                    else if (axi_i.aw_valid) begin
                        hyper_axi_state <= WRITE_ADDRESS;
                    end
                end
                READ_ADDRESS: begin
                    if(trans_ready_i) begin
                        hyper_axi_state <= READ;
                    end
                READ: begin
                    if(~rx_valid_i && trans_ready_i) begin
                        hyper_axi_state <= READY;
                    end else if(~rx_valid_i) begin
                        hyper_axi_state <= STANDBY;
                    end
                end
                WRITE_ADDRESS: begin
                    if(trans_ready_i) begin
                        hyper_axi_state <= WRITE;
                    end
                WRITE: begin
                    if()//trans_ready

                end
            endcase
        end
    end

    always @* begin
        //defaults
        axi_i.r_valid = 1'b0; //reset
        axi_i.b_valid = 1'b0; //reset
        axi_i.w_ready = 1'b0;
        axi_i.aw_ready = 1'b0;
        axi_i.ar_ready = 1'b0;

        case(hyper_axi_state)
            STANDBY: begin
            end
            READY: begin
                axi_i.aw_ready = 1'b1;
                axi_i.ar_ready = 1'b1;
            end
            READ_ADDRESS: begin
                axi_i.ar_ready = 1'b1;
                trans_valid_o = 1'b1; //TODO: Wait for trans_ready_i
                mode_write = 1'b1;
            end
            READ: begin
                mode_write = 1'b0;
            end
            WRITE_ADDRESS: begin
                axi.aw_ready = 1'b1;
                trans_valid_o = 1'b1;
                mode_write = 1'b0;
            end
            WRITE: begin
                axi_i.w_ready = 1'b1;
                trans_valid_o = 1'b1;
                mode_write = 1'b1;
            end
        endcase
    end
endmodule
