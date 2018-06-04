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
    
    input logic [NR_CS*64-1:0]      config_addr_mapping,
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

    input logic                     b_valid_i,
    output logic                    b_ready_o,
    input logic                     b_last_i,
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
    logic decode_error;
    logic slv_error;
    logic bad_address;
    logic[BURST_WIDTH-1:0] read_cnt;

    //Connect/MUX trans signals to address write and read channels 
    generate
      for(genvar i=0; i<=NR_CS-1; i++) begin
        assign trans_cs_o[i] = (config_addr_mapping[2*32*i+62:2*32*i+32] >= trans_address_o[30:0] ) && ( trans_address_o[30:0] >= config_addr_mapping[2*32*i+30:2*32*i]); 
      end
    endgenerate

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_decode_error
        if(~rst_ni) begin
            decode_error <= 0;
        end else if(axi_i.aw_valid || axi_i.ar_valid) begin
            decode_error <= bad_address;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_read_cnt
        if(~rst_ni) begin
            read_cnt <= 0;
        end else if (axi_i.ar_valid && axi_i.ar_ready) begin
            read_cnt <= axi_i.ar_len + 1;
        end
    end
    //Combinatorial
    assign bad_address = ~(trans_cs_o[0] || trans_cs_o[1]);

    assign trans_address_o = trans_write_o ? axi_i.aw_addr : axi_i.ar_addr;
    assign trans_burst_o = (trans_write_o ? axi_i.aw_len : axi_i.ar_len)+ 1;
    assign trans_burst_type_o = trans_write_o ? axi_i.aw_burst[0] : axi_i.ar_burst[0];
    assign trans_address_space_o = trans_write_o ? axi_i.aw_addr[31] : axi_i.ar_addr[31]; 

    //Data not changed within this module
    assign tx_data_o = axi_i.w_data;
    assign axi_i.r_data = rx_data_i;
    assign tx_strb_o = ~axi_i.w_strb; //WSTRB HIGH, RWDS LOW -> valid

    //Directly to FIFO
    //Write handshake
    assign tx_valid_o = axi_i.w_valid && ~decode_error && axi_i.b_resp != 2'b10;
    assign axi_i.w_ready = tx_ready_i; //is set anyway
    //Read handshake & last
    assign axi_i.r_valid = rx_valid_i || (read_cnt >= 9'b0 && decode_error);
    assign rx_ready_o = axi_i.r_ready || (read_cnt >= 9'b0 && decode_error);
    assign axi_i.r_last = rx_last_i;

    assign b_ready_o = axi_i.b_ready;

    typedef enum logic[2:0] {WRITE_READY, WRITE, WRITE_SLV_ERROR, WRITE_RESP} write_t;
    (* keep = "true" *) write_t write_state;

    typedef enum logic[2:0] {READ_READY, READ, READ_RESP, READ_ERROR} read_t;
    (* keep = "true" *) read_t read_state;

    typedef enum logic[2:0] {TRANS_START, TRANS_CHECK_READ_ADDR, TRANS_CHECK_WRITE_ADDR, TRANS_READ, TRANS_WRITE, TRANS_WRITE_END, TRANS_READ_END} trans_t;
    (* keep = "true" *) trans_t trans_state;

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
                    if(axi_i.w_last) begin
                        write_state <= WRITE_RESP;
                    end else if (b_error_i) begin
                        write_state <= WRITE_SLV_ERROR;
                    end
                end
                WRITE_SLV_ERROR: begin
                    if(axi_i.b_valid && axi_i.b_ready) begin
                        write_state <= WRITE_READY;
                    end
                end
                WRITE_RESP: begin
                    if(axi_i.b_valid && axi_i.b_ready) begin //b_resp gets read when handshake happens, either an error or valid & last
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
            WRITE_SLV_ERROR: begin
                if (b_error_i && b_valid_i) begin
                    axi_i.b_valid = 1'b1;
                    axi_i.b_resp = 2'b10;
                end
            end
            WRITE_RESP: begin
                if (b_valid_i && b_last_i) begin
                    axi_i.b_valid = 1'b1;
                    axi_i.b_resp = 2'b00;
                end if (decode_error) begin
                    axi_i.b_valid = 1'b1;
                    axi_i.b_resp = 2'b11;
                end
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
                    end if((read_cnt == 9'b0 ||rx_last_i) && axi_i.r_ready && axi_i.r_valid) begin
                        read_state <= READ_READY;
                    end else if (axi_i.r_ready && axi_i.r_valid) begin
                        read_cnt <= read_cnt - 1;
                    end
                end
                READ_ERROR: begin //Have to signal valid response with every read
                    if((read_cnt == 8'b0 || rx_last_i)  && axi_i.r_ready && axi_i.r_valid) begin
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
                if(decode_error) begin
                    axi_i.r_resp = 2'b11;
                end
            end
            READ_ERROR: begin
                axi_i.r_resp = 2'b10;
                if(decode_error) begin
                    axi_i.r_resp = 2'b11;
                end
            end
        endcase
    end

    //ATM only to solve simultaneous access
    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_trans_t
        if(~rst_ni) begin
            trans_state <= TRANS_START;
        end else begin
            case(trans_state)
                TRANS_START: begin
                    if(axi_i.ar_valid) begin
                        trans_state <= TRANS_CHECK_READ_ADDR;
                    end else if(axi_i.aw_valid) begin
                        trans_state <= TRANS_CHECK_WRITE_ADDR;
                    end
                end
                TRANS_CHECK_READ_ADDR: begin
                     if(axi_i.ar_valid && ~bad_address) begin
                        trans_state <= TRANS_READ;
                    end else if(axi_i.ar_valid && bad_address) begin
                        trans_state <= TRANS_READ_END;
                    end
                end
                TRANS_CHECK_WRITE_ADDR: begin
                    if(axi_i.aw_valid && ~bad_address) begin
                        trans_state <= TRANS_WRITE;
                    end else if (axi_i.aw_valid && bad_address) begin
                        trans_state <= TRANS_WRITE_END;
                    end 
                end
                TRANS_READ: begin
                    if(~trans_ready_i) begin
                        trans_state <= TRANS_READ;
                    end else begin
                        trans_state <= TRANS_READ_END;
                    end
                end 
                TRANS_WRITE: begin
                    if(~trans_ready_i) begin
                        trans_state <= TRANS_WRITE;
                    end else begin
                        trans_state <= TRANS_WRITE_END;
                    end
                end 
                TRANS_READ_END: begin
                    trans_state <= TRANS_START;
                end
                TRANS_WRITE_END: begin
                    trans_state <= TRANS_START;
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
            TRANS_READ: begin
                trans_write_o = 1'b0;
                trans_valid_o = 1'b1;
            end
            TRANS_WRITE: begin
                trans_write_o = 1'b1;
                trans_valid_o = 1'b1;
            end
            TRANS_CHECK_READ_ADDR: begin
                trans_write_o = 1'b0;
            end
            TRANS_CHECK_WRITE_ADDR: begin
                trans_write_o = 1'b1;
            end
            TRANS_READ_END: begin
                trans_write_o = 1'b0;
                axi_i.ar_ready = 1'b1;
            end
            TRANS_WRITE_END: begin
                trans_write_o = 1'b1;
                axi_i.aw_ready = 1'b1;
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