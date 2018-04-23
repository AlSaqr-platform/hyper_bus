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

    logic                          clk0;        //Clk for phy and FIFOS
    logic                          clk90;
    //TODO: cdc_fifo_gray for TX/RX from axi to phy
    logic                          tx_valid_o;
    logic                          tx_ready_i;
    logic [15:0]                   tx_data_o;
    logic [1:0]                    tx_strb_o;   // mask data
    // receiving channel
    logic                          rx_valid_i;
    logic                          rx_ready_o;
    logic [15:0]                   rx_data_i;
    logic                          rx_last_i;

    //Connecting phy to TX
    logic [15:0]                   tx_data_i;
    logic [1:0]                    tx_strb_i;
    logic [15:0]                   rx_data_o;
    logic                          rx_last_o;
    logic                          rx_valid_o;
    logic                          rx_ready_i;
    logic                          tx_valid_i;
    logic                          tx_ready_o;

    //Direct trans to phy
    logic                          trans_valid_o;
    logic                          trans_ready_i;
    logic [31:0]                   trans_address_o;
    logic [NR_CS-1:0]              trans_cs_o;        // chipselect
    logic                          trans_write_o;     // transaction is a write
    logic [BURST_WIDTH-1:0]        trans_burst_o;
    logic                          trans_burst_type_o;
    logic                          trans_address_space_o;
    logic                          trans_error_i;
    logic [15:0]                   config_cs_max_o;

    logic                          mode_write;
    logic [7:0]                    burst_length;
    

    // logic                          data_sel;
    
    // always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data_en
    //     if(~rst_ni) begin
    //         data_sel <= 0;
    //     end else begin
    //         data_sel <= ~data_sel;
    //     end
    // end
    assign cfg_i.ready = 1'b1;
    assign trans_burst_o = mode_write ? axi_i.aw_len : axi_i.ar_len; //Burst length, there is also also burst size 2^0, ... , 2^7
    assign tx_valid_o = axi_i.w_data;
    
    clk_gen ddr_clk (
        .clk_i    ( clk_i  ),
        .rst_ni   ( rst_ni ),
        .clk0_o   ( clk0   ),
        .clk90_o  ( clk90  ),
        .clk180_o (        ),
        .clk270_o (        )
    );

    hyperbus_phy hyperbus_phy_i (
        .clk0                         ( clk0                  ),
        .clk90                        ( clk90                 ),
        .rst_ni                       ( rst_ni                ),

        .config_t_latency_access      ( 32'h6                 ),
        .config_t_latency_additional  ( 32'h6                 ),
        .config_t_cs_max              ( 32'd666               ),
        .config_t_read_write_recovery ( 32'h6                 ),
        .config_t_rwds_delay_line     ( 32'd2000              ),

        .trans_valid_i                ( trans_valid_o         ),
        .trans_ready_o                ( trans_ready_i         ),
        .trans_address_i              ( trans_address_o       ),
        .trans_cs_i                   ( trans_cs_o            ),
        .trans_write_i                ( trans_write_o         ),
        .trans_burst_i                ( trans_burst_o         ),
        .trans_burst_type_i           ( trans_burst_type_o    ),
        .trans_address_space_i        ( trans_address_space_o ),
        .trans_error_o                ( trans_error_i         ),

        .tx_valid_i                   ( tx_valid_i            ),
        .tx_ready_o                   ( tx_ready_o            ),
        .tx_data_i                    ( tx_data_i             ),
        .tx_strb_i                    ( tx_strb_i             ),

        .rx_valid_o                   ( rx_valid_o            ),
        .rx_ready_i                   ( rx_ready_i            ),
        .rx_data_o                    ( rx_data_o             ),
        .rx_last_o                    ( rx_last_o             ),

        .hyper_cs_no                  ( hyper_cs_no           ),
        .hyper_ck_o                   ( hyper_ck_o            ),
        .hyper_ck_no                  ( hyper_ck_no           ),
        .hyper_rwds_o                 ( hyper_rwds_o          ),
        .hyper_rwds_i                 ( hyper_rwds_i          ),
        .hyper_rwds_oe_o              ( hyper_rwds_oe_o       ),
        .hyper_dq_i                   ( hyper_dq_i            ),
        .hyper_dq_o                   ( hyper_dq_o            ),
        .hyper_dq_oe_o                ( hyper_dq_oe_o         ),
        .hyper_reset_no               ( hyper_reset_no        )
);
    // TODO: Check if FSM is correct
    // TODO:     axi_i.b_valid, Write done


    //Write data, TX CDC FIFO
    assign tx_data_o = axi_i.w_valid; //Input to fifo
    assign tx_strb_o = mode_write ? ~axi_i.w_strb : 2'b0; //WSTRB HIGH, RWDS LOW -> valid
    assign axi_i.w_ready = tx_ready_i;

    cdc_fifo_gray  #(.T(logic[17:0]), .LOG_DEPTH(3)) i_cdc_TX_fifo ( 
      .src_rst_ni  ( rst_ni                 ),
      .src_clk_i   ( clk_i                  ),//hyperbus
      .src_data_i  ( {tx_data_o, tx_strb_o} ),
      .src_valid_i ( tx_valid_o             ),
      .src_ready_o ( tx_ready_i             ),
    
      .dst_rst_ni  ( rst_ni                 ),
      .dst_clk_i   ( clk0                   ),//hyperbus_phy
      .dst_data_o  ( {tx_data_i, tx_strb_i} ),
      .dst_valid_o ( tx_valid_i             ),
      .dst_ready_i ( tx_ready_o             )
    ); 

    //Read data, RX CDC FIFO
    assign axi_i.r_valid = rx_valid_i;
    assign rx_ready_o = axi_i.r_ready;
    // assign axi_i.r_data = rx_data_i;
    assign axi_i.r_last = rx_last_i;
    assign axi_i.r_user = 1'b0;
    assign axi_i.r_resp = 1'b0;
    assign axi_i.r_id = 1'b0;


    cdc_fifo_gray  #(.T(logic[16:0]), .LOG_DEPTH(3)) i_cdc_RX_fifo ( 
      .src_rst_ni  ( rst_ni                 ),
      .src_clk_i   ( clk0                   ),//hyperbus_phy
      .src_data_i  ( {rx_data_o, rx_last_o} ),
      .src_valid_i ( rx_valid_o             ),
      .src_ready_o ( rx_ready_i             ),
    
      .dst_rst_ni  ( rst_ni                 ),
      .dst_clk_i   ( clk_i                  ),//hyperbus
      .dst_data_o  ( {rx_data_i, rx_last_i} ),
      .dst_valid_o ( rx_valid_i             ),
      .dst_ready_i ( rx_ready_o             )
    ); 

    assign axi_i.r_data = rx_data_i;


    //Assign axi_i to trans data
    assign trans_valid_o = mode_write ? axi_i.aw_valid : axi_i.ar_valid;
    assign axi_i.ar_ready = trans_ready_i; //TODO: both to the same?
    assign axi_i.aw_ready = trans_ready_i;
    assign trans_cs_o = 1'b1;
    assign trans_address_o = mode_write ? axi_i.aw_addr : axi_i.ar_addr;
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

    assign trans_address_space_o = 1'b0; //Memory space

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
endmodule
