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

module hyperbus_axi #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2
)(
    input logic                     clk_i,          // Clock
    input logic                     rst_ni,         // Asynchronous reset active low
    
    AXI_BUS.in                      axi_i,

    input logic [15:0]              rx_data_i,
    input logic                     rx_last_i,
    input logic                     rx_valid_i,
    output logic                    rx_ready_o,

    output logic [15:0]             tx_data_o,
    output logic [1:0]              tx_strb_o,
    output logic                    tx_valid_o,
    input logic                     tx_ready_i,

    //Direct trans to phy
    output logic                    trans_valid_o,
    input logic                     trans_ready_i,
    output logic [31:0]             trans_address_o,
    output logic [NR_CS-1:0]        trans_cs_o,        // chipselect
    output logic                    trans_write_o,     // transaction is a write
    output logic [BURST_WIDTH-1:0]  trans_burst_o,
    output logic                    trans_burst_type_o,
    output logic                    trans_address_space_o,
    input logic                     trans_error_i,
    output logic [15:0]             config_cs_max_o

);

    logic                           mode_write;

    
    //Write data, TX CDC FIFO
    assign tx_data_o = axi_i.w_data; //Input to fifo
    assign tx_valid_o = axi_i.w_valid;
    assign tx_strb_o = mode_write ? ~axi_i.w_strb : 2'b0; //WSTRB HIGH, RWDS LOW -> valid
    assign axi_i.w_ready = tx_ready_i;

    //Read data, RX CDC FIFO
    assign axi_i.r_valid = rx_valid_i;
    assign axi_i.r_data = rx_data_i;
    assign axi_i.r_last = rx_last_i;
    assign rx_ready_o = axi_i.r_ready;
    //Required signals
    assign axi_i.r_id = 1'b0;
    assign axi_i.r_user = 1'b0;

    //AX signals to PHY (trans)
    //axi_i.ar_id
    assign axi_i.aw_ready = trans_ready_i;
    assign axi_i.ar_ready = trans_ready_i; //TODO: both to the same?
    assign trans_valid_o = mode_write ? axi_i.aw_valid : axi_i.ar_valid;
    assign trans_address_o = mode_write ? axi_i.aw_addr : axi_i.ar_addr;
    assign trans_burst_o = (mode_write ? axi_i.aw_len : axi_i.ar_len) + 1; //Burst length, there is also also burst size 2^0, ... , 2^7
  
    assign trans_cs_o = 1'b1;
    assign trans_write_o = mode_write;
    
    //AXI: Table A3-3 Burst type encoding
    //AxBURST[1:0] Burst type
    //0b00 FIXED
    //0b01 INCR
    //0b10 WRAP
    //0b11 Reserved
    //Hyperram
    //Burst Type=0 indicates wrapped burst
    //Burst Type=1 indicates linear burst
    assign trans_burst_type_o = mode_write ? axi_i.aw_burst[0] : axi_i.ar_burst[0];

    assign trans_address_space_o = mode_write ? axi_i.aw_addr[31] : axi_i.ar_addr[31]; //Memory space

    typedef enum logic[3:0] {STANDBY, READY, READ, WRITE, WRITE_RESPONSE} hyper_axi_state_t;
    hyper_axi_state_t hyper_axi_state;

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_hyper_axi_state
        if(~rst_ni) begin
            hyper_axi_state <= READY;
        end else begin
            case(hyper_axi_state)
                READY: begin
                    if(axi_i.ar_valid) begin
                        hyper_axi_state <= READ;
                    end else if (axi_i.aw_valid) begin
                        hyper_axi_state <= WRITE;
                    end
                end
                READ: begin
                    if(~trans_error_i && ~rx_last_i) begin //rx_valid_i && axi_i.r_ready &&
                        hyper_axi_state <= READ;
                    end else begin //TODO: better logic also for WRITE
                        hyper_axi_state <= READY;
                    end
                end
                WRITE: begin
                    if(tx_ready_i && ~axi_i.w_last) begin //~trans_error_i && axi_i.w_valid && 
                        hyper_axi_state <= WRITE_RESPONSE;
                    end else begin //TODO: Deal with error
                        hyper_axi_state <= READY;
                    end
                end
                WRITE_RESPONSE: begin
                    if(axi_i.b_ready == 1'b1) begin
                        hyper_axi_state <= READY;
                    end
                end
            endcase
        end
    end

    always @* begin
        //defaults
        //TODO: r_valid connected to rx_valid_i
        // axi_i.r_valid = 1'b0; //Reset, Read valid. (channel is signaling the required read data)
        axi_i.b_valid = 1'b0; //Reset, Write response valid. (signaling valid write response)
        // axi_i.w_ready = 1'b0; //Write ready. (can accept the write data)
        //axi_i.aw_ready = 1'b0; //Write address ready. (ready to accept an address)
        //axi_i.ar_ready = 1'b0; //Read address ready. (ready to accept an address)
        //trans_valid_o = 1'b0;
        mode_write = 1'b1;
        case(hyper_axi_state)
            READY: begin
                //axi_i.aw_ready = 1'b1; //A3.2.2 Specification recommends default HIGH.
                //axi_i.ar_ready = 1'b1;
            end
            READ: begin
                mode_write = 1'b0;
            end
            WRITE: begin
                //axi_i.w_ready = 1'b1;
                //trans_valid_o = 1'b1;
                mode_write = 1'b1;
            end
            WRITE_RESPONSE: begin
                axi_i.b_valid = 1'b1;
            end
        endcase
    end
endmodule // hyperbus_axi