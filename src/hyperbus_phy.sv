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
    input  logic [7:0]             tx_data_i,
    input  logic                   tx_strb_i,   // mask data
    // receiving channel
    output logic                   rx_valid_o,
    input  logic                   rx_ready_i,
    output logic [7:0]             rx_data_o,
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

endmodule