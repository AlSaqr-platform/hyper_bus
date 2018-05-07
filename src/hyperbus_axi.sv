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
    parameter NR_CS = 2,

    parameter AXI_IW = 10
)(
    input logic                     clk_i,          // Clock
    input logic                     rst_ni,         // Asynchronous reset active low
    
    AXI_BUS.in                      axi_i,

    input logic [15:0]              rx_data_i,
    input logic                     rx_last_i,
    input logic                     rx_error_i,
    input logic                     rx_valid_i,
    output logic                    rx_ready_o,

    output logic [15:0]             tx_data_o,
    output logic [1:0]              tx_strb_o,
    output logic                    tx_valid_o,
    input logic                     tx_ready_i,

    input logic                     b_last_i, //Valid
    input logic                     b_error_i,

    //Direct trans to phy
    output logic                    trans_valid_o,
    input logic                     trans_ready_i,
    output logic [31:0]             trans_address_o,
    output logic [NR_CS-1:0]        trans_cs_o,        // chipselect
    output logic                    trans_write_o,     // transaction is a write
    output logic [BURST_WIDTH-1:0]  trans_burst_o,
    output logic                    trans_burst_type_o,
    output logic                    trans_address_space_o
);

    logic [AXI_IW-1:0]              axi_trans_id;

    typedef enum logic[3:0] {STANDBY, READY, READ_ADDR, READ, WRITE_ADDR, WRITE, WRITE_RESPONSE, WRITE_ERROR} hyper_axi_state_t;
    hyper_axi_state_t hyper_axi_state;

    assign tx_data_o = axi_i.w_data;
    assign axi_i.r_id = axi_trans_id;
    assign axi_i.b_id = axi_trans_id;

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_axi_trans_id
        if(~rst_ni) begin
            axi_trans_id <= 'b0;
        end else if (axi_i.aw_valid) begin
            axi_trans_id <= axi_i.aw_id;
        end else if (axi_i.ar_valid) begin
            axi_trans_id <= axi_i.ar_id;
        end
    end
    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_hyper_axi_state
        if(~rst_ni) begin
            hyper_axi_state <= READY;
        end else begin
            case(hyper_axi_state)
                READY: begin
                    if(axi_i.ar_valid) begin
                        hyper_axi_state <= READ_ADDR;
                    end else if (axi_i.aw_valid) begin
                        hyper_axi_state <= WRITE_ADDR;
                    end
                end
                READ_ADDR: begin
                    if(trans_ready_i) begin
                        hyper_axi_state <= READ;
                    end
                end
                READ: begin
                    if(~(rx_last_i && rx_valid_i)) begin //rx_valid_i && axi_i.r_ready &&
                        hyper_axi_state <= READ;
                    end else begin 
                        hyper_axi_state <= READY;
                    end
                end
                WRITE_ADDR: begin
                    if(trans_ready_i) begin
                        hyper_axi_state <= WRITE;
                    end
                end
                WRITE: begin
                    if(~b_error_i) begin // && axi_i.w_valid && 
                        hyper_axi_state <= WRITE;
                    end if (axi_i.w_last) begin
                        hyper_axi_state <= WRITE_RESPONSE;
                    end
                end
                WRITE_RESPONSE: begin
                    if(b_last_i == 1'b1) begin
                        hyper_axi_state <= READY;
                    end if(b_error_i) begin
                        hyper_axi_state <= WRITE_ERROR;
                    end
                end
                WRITE_ERROR: begin
                     if(axi_i.b_ready == 1'b1) begin
                        hyper_axi_state <= READY;
                    end
                end
            endcase
        end
    end

    always @* begin
        //defaults
        axi_i.ar_ready = 1'b0; //Read address ready. (ready to accept an address)
        axi_i.r_valid = 1'b0; //Reset, Read valid. (channel is signaling the required read data)
        axi_i.r_data = 1'b0;
        axi_i.r_last = 1'b0;
        axi_i.r_resp= 2'b00;
        rx_ready_o = 1'b0;

        axi_i.aw_ready = 1'b0; //Write address ready. (ready to accept an address)
        axi_i.w_ready = 1'b0; //Write ready. (can accept the write data)
        axi_i.b_valid = 1'b0; //Reset, Write response valid. (signaling valid write response)
        axi_i.b_resp = 2'b00;
   
        trans_cs_o = 1'b1;
        trans_valid_o = 1'b0;
        trans_address_o = 'b0;
        trans_burst_o = 1'b0;
        trans_burst_type_o = 1'b0;
        trans_address_space_o = 1'b0;
        trans_write_o = 1'b0;
        
        tx_valid_o = 1'b0;
        tx_strb_o = 2'b00;
    
        //Required signals
        axi_i.r_user = 1'b0;
        axi_i.b_user = 1'b0;

        case(hyper_axi_state)
            READY: begin
                //axi_i.aw_ready = 1'b1; //A3.2.2 Specification recommends default HIGH.
                //axi_i.ar_ready = 1'b1;
            end
            READ_ADDR: begin
                trans_valid_o = 1'b1;
                axi_i.ar_ready = trans_ready_i; 
                trans_address_o = axi_i.ar_addr;
                trans_burst_o = axi_i.ar_len + 1'b1;
                trans_burst_type_o = axi_i.ar_burst[0];
                trans_address_space_o = axi_i.ar_addr[31]; //Memory space  
                trans_write_o = 1'b0;
                if (rx_error_i) begin
                    axi_i.r_resp = 2'b10;
                end
            end
            READ: begin
                axi_i.r_valid = rx_valid_i;
                axi_i.r_data = rx_data_i;
                axi_i.r_last = rx_last_i;
                rx_ready_o = axi_i.r_ready;

                if (rx_error_i) begin
                    axi_i.r_resp = 2'b10;
                end
            end
            WRITE_ADDR: begin
                trans_valid_o = 1'b1;
                axi_i.aw_ready = trans_ready_i; 
                trans_address_o = axi_i.aw_addr;
                trans_burst_o = axi_i.aw_len + 1;
                trans_burst_type_o = axi_i.aw_burst[0];
                trans_address_space_o = axi_i.aw_addr[31]; //Memory space
                trans_write_o = 1'b1;
                if (b_error_i) begin
                    axi_i.r_valid = 1'b1;
                    axi_i.r_resp = 2'b10;
                end
            end
            WRITE: begin
                tx_valid_o = axi_i.w_valid;
                tx_strb_o = ~axi_i.w_strb; //WSTRB HIGH, RWDS LOW -> valid
                axi_i.w_ready = tx_ready_i;
            end
            WRITE_RESPONSE: begin
                if (b_last_i) begin
                    axi_i.b_valid = 1'b1;
                    axi_i.b_resp = 2'b00;
                end
            end
            WRITE_ERROR: begin
                axi_i.b_valid = 1'b1;
                axi_i.b_resp = 2'b10;
            end
        endcase
    end
endmodule // hyperbus_axi