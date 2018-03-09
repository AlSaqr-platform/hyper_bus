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
// Description: Connect the AXI interface with the actual HyperBus

module hyperbus_phy #(
    int unsigned BURST_WIDTH = 12,
    int unsigned NR_CS = 2
)(
    input logic                    clk_i,    // Clock
    input logic                    rst_ni,   // Asynchronous reset active low
    // transactions
    input  logic                   trans_valid_i,
    output logic                   trans_ready_o,
    input  logic [31:0]            trans_address_i,
    input  logic [NR_CS-1:0]       trans_cs_i,        // chipselect
    input  logic                   trans_write_i,     // transaction is a write
    input  logic [BURST_WIDTH-1:0] trans_burst_i,
    // transmitting
    input  logic                   tx_valid_i,
    output logic                   tx_ready_o,
    input  logic [15:0]            tx_data_i,
    input  logic [1:0]             tx_strb_i,   // mask data
    // receiving channel
    output logic                   rx_valid_o,
    input  logic                   rx_ready_i,
    output logic [15:0]            rx_data_o,
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

    logic [47:0] cmd_addr;
    logic [15:0] data_out;
    logic [1:0]  cmd_addr_sel;

    logic clock_enable = 1'b0;

    logic clk0;
    logic clk90;
    logic clk180;
    logic clk270;

    clk_gen ddr_clk (
        .clk_i    ( clk_i  ),
        .rst_ni   ( rst_ni ),
        .clk0_o   ( clk0   ),
        .clk90_o  ( clk90  ),
        .clk180_o ( clk180 ),
        .clk270_o ( clk270 )
    );

    pulp_clock_gating hyper_ck_gating (
        .clk_i      ( clk90        ),
        .en_i       ( clock_enable ),
        .test_en_i  ( 1'b0         ),
        .clk_o      ( hyper_ck_o   )
    ); 

    pulp_clock_inverter hyper_ck_no_inv (
        .clk_i ( hyper_ck_o  ),
        .clk_o ( hyper_ck_no )
    );


    assign hyper_rwds_oe_o = 0;
    assign hyper_cs_no = ~clock_enable;
  
    genvar i;
    generate
      for(i=0; i<=7; i++)
      begin: ddr_out_bus
        ddr_out ddr_data (
          .rst_ni (rst_ni),
          .clk_i (clk0),
          .d0_i (data_out[i+8]),
          .d1_i (data_out[i]),
          .q_o (hyper_dq_o[i])
        );
      end
    endgenerate


    cmd_addr_gen cmd_addr_gen (
        .rw_i            ( ~trans_write_i  ),
        .address_space_i ( 1'b0            ),
        .burst_type_i    ( 1'b1            ),
        .address_i       ( trans_address_i ),
        .cmd_addr_o      ( cmd_addr        )
    );

    always_ff @(posedge clk0 or negedge rst_ni) begin : proc_cmd_addr_sel
        if(~rst_ni) begin
            cmd_addr_sel <= 0;
        end else if (trans_valid_i && cmd_addr_sel != 2'h3) begin
            cmd_addr_sel <= cmd_addr_sel + 1;
        end
    end

    always @(cmd_addr_sel or trans_valid_i) begin
        if (trans_valid_i) begin
            case(cmd_addr_sel)
                0: data_out = cmd_addr[47:32];
                1: data_out = cmd_addr[31:16];
                2: data_out = cmd_addr[15:0];
                default: data_out = '0;
            endcase // cmd_addr_sel
        end else begin
            data_out = '0;
        end
    end

    //use data bus as input after sending cmd-addr
    always_ff @(posedge clk0 or negedge rst_ni) begin : proc_hyper_dq_oe_o
        if(~rst_ni) begin
            hyper_dq_oe_o <= 1;
        end else if(cmd_addr_sel == 2'h3) begin
            hyper_dq_oe_o <= 0;
        end
    end

    always_ff @(posedge clk180 or negedge rst_ni) begin : proc_clock_enable
        if(~rst_ni) begin
            clock_enable <= 0;
        end else if (trans_valid_i) begin
            clock_enable <= 1;
        end else begin
            clock_enable <= 0;
        end
    end

    assign hyper_reset_no = 1;

endmodule
