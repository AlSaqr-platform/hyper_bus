// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// Description: A Hyperbus transciever with a system-synchronous interface.
//              Handles all clock crossing and asynchronous manipulation, but
//              requires external system-synchronous control for a full PHY.

// Author: Armin Berger <bergerar@ethz.ch>
// Author: Stephan Keck <kecks@ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// TODO: delay lines!

module hyperbus_trx #(
    parameter int unsigned NumChips = 2
)(
    // Global signals
    input  logic            clk_0_i,
    input  logic            clk_90_i,
    input  logic            clk_test_i,
    input  logic            rst_ni,
    input  logic            test_mode_i,
    // Transciever control: facing controller
    input  logic                   clk_ena_i,
    input  logic [NumChips-1:0]    cs_i,
    input  logic                   cs_ena_i,
    output logic                   rwds_sample_o,
    input  logic                   rwds_sample_ena_i,

    input  logic [15:0]            tx_data_i,
    input  logic                   tx_data_oe_i,
    input  logic [1:0]             tx_rwds_i,
    input  logic                   tx_rwds_oe_i,

    input  logic                   rx_clk_ena_i,
    output logic [15:0]            rx_data_o,
    output logic                   rx_valid_o,
    input  logic                   rx_ready_i,
    // Physical interace: facing HyperBus
    output logic [NumChips-1:0]    hyper_cs_no,
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

    // Delayed clock enable synchronous with data
    logic clk_ena;

    // Intermediate RX signals for RWDS domain
    logic           rx_rwds_clk_ena;
    logic           rx_rwds_clk_orig;
    logic           rx_rwds_clk;
    logic           rx_rwds_soft_rst;
    logic [15:0]    rx_rwds_data;
    logic           rx_rwds_data_valid;
    logic           rx_rwds_fifo_ready;

    // Feed through async reset
    assign hyper_reset_no = rst_ni;

    // =================
    //    TX + control
    // =================

    // 90deg-shifted differential output clock, sampling output bytes centrally
    hyperbus_clock_diff_out i_clock_diff_out (
        .in_i   ( clk_90_i      ),
        .en_i   ( clk_ena       ),
        .out_o  ( hyper_ck_o    ),
        .out_no ( hyper_ck_no   )
    );

    // Synchronize output chip select to shifted differential output clock
    always_ff @(posedge clk_90_i or negedge rst_ni) begin : proc_ff_tx_shift90
        if (~rst_ni)    hyper_cs_no <= '1;
        else            hyper_cs_no <= cs_ena_i ? ~cs_i : '1;
    end

    // Data output DDR converters
    for (genvar i = 0; i <= 7; i++) begin: gen_ddr_tx_data
        hyperbus_ddr_out #(
            .Init   ( 1'b0 )
        ) i_ddr_tx_data (
            .clk_i  ( clk_0_i           ),
            .rst_ni ( rst_ni            ),
            .d0_i   ( tx_data_i  [i+8]  ),
            .d1_i   ( tx_data_i  [i]    ),
            .q_o    ( hyper_dq_o [i]    )
        );
    end

    // RWDS output DDR converter
    hyperbus_ddr_out #(
        .Init   ( 1'b0 )
    ) i_ddr_tx_rwds (
        .clk_i  ( clk_0_i       ),
        .rst_ni ( rst_ni        ),
        .d0_i   ( tx_rwds_i [1] ),
        .d1_i   ( tx_rwds_i [0] ),
        .q_o    ( hyper_rwds_o  )
    );

    // Delay output, clock enables to be synchronous with DDR-converted data
    // The delayed clock also ensures t_CSS is respected at the start, end of CS
    always_ff @(posedge clk_0_i or negedge rst_ni) begin : proc_ff_tx_delay
        if(~rst_ni) begin
            hyper_rwds_oe_o <= 1'b0;
            hyper_dq_oe_o   <= 1'b0;
            clk_ena         <= 1'b0;
        end else begin
            hyper_rwds_oe_o <= tx_rwds_oe_i;
            hyper_dq_oe_o   <= tx_data_oe_i;
            clk_ena         <= clk_ena_i;
        end
    end


    // Sample RWDS on demand for extra latency determination
    always_ff @(posedge clk_0_i or negedge rst_ni) begin : proc_ff_rwds_sample
        if (~rst_ni)                rwds_sample_o <= '0;
        else if (rwds_sample_ena_i) rwds_sample_o <= hyper_rwds_i;
    end

    // ========
    //    RX
    // ========

    // Synchronize RX clock enable into RWDS domain
    // TODO: Why was this clocked without phase shift??
    always_ff @(posedge clk_0_i or negedge rst_ni) begin : proc_ff_rx_delay
        if (~rst_ni)    rx_rwds_clk_ena <= '0;
        else            rx_rwds_clk_ena <= rx_clk_ena_i;
    end

    // Gate RWDS clock with RX clock enable
    assign rx_rwds_clk_orig = hyper_rwds_i & rx_rwds_clk_ena;

     // Reset RX state on async reset or on gated clock (whenever inactive)
    assign rx_rwds_soft_rst = ~rst_ni | (~rx_rwds_clk_ena & ~test_mode_i);

    // RX data is valid one cycle after each RX soft reset
    always_ff @(posedge rx_rwds_clk or posedge rx_rwds_soft_rst) begin : proc_read_in_valid
        if (rx_rwds_soft_rst)   rx_rwds_data_valid <= 1'b0;
        else                    rx_rwds_data_valid <= 1'b1;
    end

    // If testing, replace gated RWDS clock with test clock
    tc_clk_mux2 i_rx_rwds_clk_mux (
        .clk0_i    ( rx_rwds_clk_orig   ),
        .clk1_i    ( clk_test_i         ),
        .clk_sel_i ( test_mode_i        ),
        .clk_o     ( rx_rwds_clk        )
    );

    // Data input DDR converters
    for (genvar i = 0; i <= 7; i++) begin: gen_ddr_rx_data
        hyperbus_ddr_in i_ddr_rx_data (
            .clk_i  ( rx_rwds_clk                           ),
            .rst_ni ( rst_ni                                ),
            .data_i ( hyper_dq_i[i]                         ),
            .enable ( 1'b1                                  ),
            .data_o ( {rx_rwds_data[i+8], rx_rwds_data[i]}  )
        );
    end

    // Cross input data from RWDS domain into system domain
    cdc_fifo_gray  #(
        .T(logic[15:0]),
        .LOG_DEPTH(3)
    ) i_rx_rwds_cdc_fifo (
        // RWDS domain
        .src_clk_i   ( rx_rwds_clk        ),
        .src_rst_ni  ( rst_ni             ),
        .src_data_i  ( rx_rwds_data       ),
        .src_valid_i ( rx_rwds_data_valid ),
        .src_ready_o ( rx_rwds_fifo_ready ),
        // System domain
        .dst_clk_i   ( clk_0_i      ),
        .dst_rst_ni  ( rst_ni       ),
        .dst_data_o  ( rx_data_o    ),
        .dst_valid_o ( rx_valid_o   ),
        .dst_ready_i ( rx_ready_i   )
    );

    // assert that the FIFO does not drop data in simulation
    `ifndef SYNTHESIS
    always @(negedge rx_rwds_fifo_ready) assert(rx_rwds_fifo_ready)
        else $error("%m: HyperBus RX FIFO must always be ready to receive data");
    `endif

endmodule
