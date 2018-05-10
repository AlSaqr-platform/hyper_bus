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

    //Connect/MUX trans signals to address write and read channels 
    assign trans_cs_o = 1'b1; //Address range

    assign trans_address_o = trans_write_o ? axi_i.aw_addr : axi_i.ar_addr;
    assign trans_burst_o = (trans_write_o ? axi_i.aw_len : axi_i.ar_len)+ 1;
    assign trans_burst_type_o = trans_write_o ? axi_i.aw_burst[0] : axi_i.ar_burst[0];
    assign trans_address_space_o = trans_write_o ? axi_i.aw_addr[31] : axi_i.ar_addr[31]; 

    //Data not changed within this module
    assign tx_data_o = axi_i.w_data;
    assign axi_i.r_data = rx_data_i;
    assign tx_strb_o = ~axi_i.w_strb; //WSTRB HIGH, RWDS LOW -> valid

    //Directly to FIFO
    assign tx_valid_o = axi_i.w_valid;
    assign axi_i.w_ready = tx_ready_i;
    assign axi_i.r_valid = rx_valid_i;
    assign axi_i.r_last = rx_last_i;
    assign rx_ready_o = axi_i.r_ready;

    typedef enum logic[3:0] {WRITE_READY, WRITE, WRITE_RESP, WRITE_ERROR} write_t;
    write_t write_state;

    typedef enum logic[3:0] {READ_READY, READ, READ_RESP, READ_ERROR} read_t;
    read_t read_state;

    typedef enum logic[3:0] {TRANS_READY, TRANS_READ, TRANS_WRITE, TRANS_FULL} trans_t;
    trans_t trans_state;

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_write_state
        if(~rst_ni) begin
            write_state <= WRITE_READY;
        end else begin
            case(write_state)
                WRITE_READY: begin
                    if(axi_i.aw_ready && axi_i.aw_valid) begin
                        write_state <= WRITE;
                    end
                end
                WRITE: begin
                    if(b_error_i) begin
                        write_state <= WRITE_ERROR;
                    end if(axi_i.w_last) begin
                        write_state <= WRITE_RESP;
                    end
                end
                WRITE_RESP: begin
                    if(b_last_i && axi_i.b_ready) begin
                        write_state <= WRITE_READY;
                    end if(b_error_i) begin
                        write_state <= WRITE_ERROR;
                    end
                end
                WRITE_ERROR: begin
                     if(axi_i.b_ready) begin
                        write_state <= WRITE_READY;
                    end
                end
            endcase //write_state
        end
    end

    always @* begin
        //defaults
        axi_i.b_valid = 1'b0;
        axi_i.b_resp = 2'b00;
        axi_i.b_user = 1'b0;
        case(write_state)
            WRITE_RESP: begin
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
    
    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_read_state
        if(~rst_ni) begin
            read_state <= READ_READY;
        end else begin
            case(read_state)
                READ_READY: begin
                    if(axi_i.ar_ready && axi_i.ar_valid) begin
                        read_state <= READ;
                    end
                end
                READ: begin
                    if(rx_error_i) begin
                        read_state <= READ_ERROR;
                    end else  if(rx_last_i) begin //axi_i.r_ready && rx_valid_i
                        read_state <= READ_READY;
                    end
                end
                READ_ERROR: begin //Have to signal valid response with every read
                    if(rx_last_i) begin
                        read_state <= READ_READY;
                    end
                end
            endcase // read_state
        end
    end

    always @* begin        
    //defaults
    axi_i.r_resp= 2'b00;
    axi_i.r_user = 1'b0;      
        case(read_state)
            READ: begin
                if(rx_error_i) begin
                    axi_i.r_resp = 2'b10;
                end
            end
            READ_ERROR: begin
                axi_i.r_resp = 2'b10;
            end
        endcase
    end

    //ATM only to solve simultaneous access
    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_trans_t
        if(~rst_ni) begin
            trans_state <= TRANS_READY;
        end else begin
            case(trans_state)
                TRANS_READY: begin
                    if(~trans_ready_i) begin
                        trans_state <= TRANS_FULL;
                    end else if(axi_i.aw_valid) begin
                        trans_state <= TRANS_WRITE;
                    end else if(axi_i.ar_valid) begin
                        trans_state <= TRANS_READ;
                    end
                end
                TRANS_READ: begin
                    if(~trans_ready_i) begin
                        trans_state <= TRANS_READY;
                    end else begin
                        trans_state <= TRANS_READ;
                    end
                end 
                TRANS_WRITE: begin
                    if(~trans_ready_i) begin
                        trans_state <= TRANS_READY;
                    end else begin
                        trans_state <= TRANS_WRITE;
                    end
                end 
                TRANS_FULL: begin
                    if(trans_ready_i) begin
                        trans_state <= TRANS_READY;
                    end
                end
            endcase //trans_state
        end
    end

    always @* begin        
    //defaults     
    trans_valid_o = 1'b0;
    trans_write_o = 1'b0;
    axi_i.aw_ready = 1'b0; 
    axi_i.ar_ready = 1'b0;
        case(trans_state)
            TRANS_READY: begin
            end 
            TRANS_READ: begin
                trans_write_o = 1'b0;
                trans_valid_o = 1'b1;
                axi_i.ar_ready = 1'b1;
            end
            TRANS_WRITE: begin
                trans_write_o = 1'b1;
                trans_valid_o = 1'b1;
                axi_i.aw_ready = 1'b1;
            end
            TRANS_FULL: begin
                axi_i.aw_ready = 1'b0;
                axi_i.ar_ready = 1'b0; 
            end
        endcase
    end

    logic [AXI_IW-1:0]              axi_trans_id;

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
endmodule // hyperbus_axi