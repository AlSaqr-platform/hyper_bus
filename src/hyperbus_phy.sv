// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// Description: The HyperBus PHY

// Author: Armin Berger <bergerar@ethz.ch>
// Author: Stephan Keck <kecks@ethz.ch>
// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// TODO: hyperflash!!!!
// TODO: rename, change t_cs_max to t_burst_max

module hyperbus_phy import hyperbus_pkg::*; #(
    parameter int unsigned NumChips     = 2,
    parameter int unsigned TimerWidth   = 4
)(
    input  logic                clk_0_i,
    input  logic                clk_90_i,
    input  logic                rst_ni,
    input  logic                clk_test_i,
    input  logic                test_mode_i,
    // Config registers
    input  hyper_cfg_t          cfg_i,
    // Transactions
    input  logic                trans_valid_i,
    output logic                trans_ready_o,
    input  hyper_tf_t           trans_i,            // TODO: increase burst width!
    input  logic [NumChips-1:0] trans_cs_i,
    // Transmitting channel
    input  logic                tx_valid_i,
    output logic                tx_ready_o,
    input  hyper_tx_t           tx_i,
    // Receiving channel
    output logic                rx_valid_o,
    input  logic                rx_ready_i,
    output hyper_rx_t           rx_o,
    // B response
    output logic                b_valid_o,
    input  logic                b_ready_i,
    output hyper_b_t            b_o,
    // Physical interface
    output logic [NumChips-1:0] hyper_cs_no,
    output logic                hyper_ck_o,
    output logic                hyper_ck_no,
    output logic                hyper_rwds_o,
    input  logic                hyper_rwds_i,
    output logic                hyper_rwds_oe_o,
    input  logic [7:0]          hyper_dq_i,
    output logic [7:0]          hyper_dq_o,
    output logic                hyper_dq_oe_o,
    output logic                hyper_reset_no
);

    // PHY state
    hyper_phy_state_t       state_d,    state_q;
    logic [TimerWidth-1:0]  timer_d,    timer_q;
    hyper_tf_t              tf_d,       tf_q;
    logic [NumChips-1:0]    cs_d,       cs_q;

    // Auxiliar control signals
    logic ctl_write_zero_lat;
    logic ctl_add_latency;
    logic ctl_burst_last;
    logic ctl_tf_burst_last;
    logic ctl_tf_burst_done;
    logic ctl_timer_one;
    logic ctl_timer_zero;
    logic ctl_timer_rwr_done;
    logic ctl_read_ena;
    logic ctl_write_ena;

    // Command-address
    hyper_phy_ca_t  ca;
    logic [15:0]    ca_tx_data;

    // Transciever IO
    logic           trx_clk_ena;
    logic           trx_cs_ena;
    logic           trx_rwds_sample;
    logic           trx_rwds_sample_ena;
    logic [15:0]    trx_tx_data;
    logic           trx_tx_data_oe;
    logic [1:0]     trx_tx_rwds;
    logic           trx_tx_rwds_oe;
    logic           trx_rx_clk_ena;
    logic [15:0]    trx_rx_data;
    logic           trx_rx_valid;
    logic           trx_rx_ready;

    // =================
    //    Transciever
    // =================

    hyperbus_trx #(
        .NumChips       ( NumChips )
    ) i_trx (
        .clk_0_i,
        .clk_90_i,
        .clk_test_i,
        .rst_ni,
        .test_mode_i,
        .clk_ena_i          ( trx_clk_ena           ),
        .cs_i               ( cs_q                  ),
        .cs_ena_i           ( trx_cs_ena            ),
        .rwds_sample_o      ( trx_rwds_sample       ),
        .rwds_sample_ena_i  ( trx_rwds_sample_ena   ),
        .tx_data_i          ( trx_tx_data           ),
        .tx_data_oe_i       ( trx_tx_data_oe        ),
        .tx_rwds_i          ( trx_tx_rwds           ),
        .tx_rwds_oe_i       ( trx_tx_rwds_oe        ),
        .rx_clk_ena_i       ( trx_rx_clk_ena        ),
        .rx_data_o          ( trx_rx_data           ),
        .rx_valid_o         ( trx_rx_valid          ),
        .rx_ready_i         ( trx_rx_ready          ),
        .hyper_cs_no,
        .hyper_ck_o,
        .hyper_ck_no,
        .hyper_rwds_o,
        .hyper_rwds_i,
        .hyper_rwds_oe_o,
        .hyper_dq_i,
        .hyper_dq_o,
        .hyper_dq_oe_o,
        .hyper_reset_no
    );

    // ==============
    //    Dataflow
    // ==============

    // Command-address
    assign ca = hyper_phy_ca_t '{
        write:      tf_q.write,
        addr_space: tf_q.address_space,
        burst_type: tf_q.burst_type,
        addr_upper: tf_q.address[31:3],
        reserved:   '0,
        addr_lower: tf_q.address[2:0]
    };

    // Data to send in CA phase: use timer to select word
    assign ca_tx_data = ca[(timer_q << 4) +: 16];

    // Write dataflow
    assign trx_tx_data  = (state_q == SendCA) ? ca_tx_data : tx_i.data;
    assign trx_tx_rwds  =  tx_i.strb;
    assign b_o          = hyper_b_t'{
        last:   ctl_tf_burst_last,
        error:  1'b0    // TODO
    };

    always_comb begin : proc_comb_tx
        trx_tx_data_oe  = 1'b0;
        trx_tx_rwds_oe  = 1'b0;
        tx_ready_o      = 1'b0;
        ctl_write_ena   = 1'b0;
        if (state_q == SendCA) begin
            trx_tx_data_oe  = 1'b1;
        end else if (state_q == Write) begin
            trx_tx_data_oe  = 1'b1;
            trx_tx_rwds_oe  = 1'b1;
            tx_ready_o      = 1'b1;
            ctl_write_ena   = tx_valid_i & tx_ready_o;
        end
    end

    // Read dataflow
    assign rx_o = hyper_rx_t'{
        data:   trx_rx_data,
        last:   ctl_tf_burst_last,
        error:  1'b0    // TODO
    };

    always_comb begin : proc_comb_rx
        rx_valid_o      = 1'b0;
        trx_rx_ready    = 1'b0;
        ctl_read_ena    = 1'b0;
        if (state_q == Read) begin
            trx_rx_ready    = rx_ready_i;
            rx_valid_o      = trx_rx_valid;
            ctl_read_ena    = rx_valid_o & rx_ready_i;
        end
    end

    // =============
    //    Control
    // =============

    // Auxiliary control signals
    assign ctl_write_zero_lat   = tf_q.address_space & tf_q.write;
    assign ctl_add_latency      = trx_rwds_sample | cfg_i.en_latency_additional;

    assign ctl_tf_burst_last    = (tf_q.burst == 1);
    assign ctl_tf_burst_done    = (tf_q.burst == 0);

    assign ctl_timer_rwr_done   = (timer_q <= 3);
    assign ctl_timer_one        = (timer_q == 1);
    assign ctl_timer_zero       = (timer_q == 0);

    assign ctl_burst_last       = ctl_timer_one | ctl_tf_burst_last;

    // FSM logic
    always_comb begin : proc_comb_phy_fsm
        // Default outputs
        trans_ready_o       = 1'b0;
        b_valid_o           = 1'b0;
        trx_cs_ena          = 1'b1;
        trx_clk_ena         = 1'b0;
        trx_rx_clk_ena      = 1'b0;
        trx_rwds_sample_ena = 1'b0;
        // Default next state
        state_d = state_q;
        timer_d = timer_q - 1;
        tf_d    = tf_q;
        cs_d    = cs_q;
        // State-dependent logic
        case (state_q)
            Idle: begin
                trx_cs_ena  = 1'b0;
                timer_d     = timer_q;
                // Signal ready for, pop next transfer
                 trans_ready_o   = 1'b1;
                if (trans_valid_i) begin
                    tf_d    = trans_i;
                    cs_d    = trans_cs_i;
                    state_d = WaitCSS;
                end
            end
            WaitCSS: begin
                // Wait for one cycle (t_CSS), then send 3 CA words
                timer_d = 2;
                state_d = SendCA;
            end
            SendCA: begin
                // Dataflow handled outside FSM
                trx_clk_ena         = 1'b1;
                trx_rwds_sample_ena = ~ctl_write_zero_lat;
                if (ctl_timer_zero) begin
                    if (ctl_write_zero_lat) begin
                        timer_d = cfg_i.t_cs_max;
                        state_d = Write;
                    end else begin
                        timer_d = TimerWidth'(cfg_i.t_latency_access) << ctl_add_latency;
                        state_d = WaitLatAccess;
                    end
                end
            end
            WaitLatAccess: begin
                trx_clk_ena = 1'b1;
                if (ctl_timer_one) begin
                    timer_d = cfg_i.t_cs_max;
                    state_d = tf_q.write ? Write : Read;
                end
            end
            Read: begin
                // TODO: ensure FIFO sufficiently vacant after resuming after stall
                // Dataflow handled outside FSM
                trx_rx_clk_ena = 1'b1;
                if (ctl_read_ena) begin
                    trx_clk_ena = 1'b1;
                    if (ctl_burst_last) begin
                        timer_d = cfg_i.t_read_write_recovery;
                        state_d = WaitRWR;
                    end
                end
            end
            Write: begin
                // Dataflow handled outside FSM
                if (ctl_write_ena) begin
                    trx_clk_ena = 1'b1;
                    if (ctl_burst_last) begin
                        timer_d = cfg_i.t_read_write_recovery;
                        state_d = SendB;
                    end
                end
            end
            SendB: begin
                trx_cs_ena = 1'b0;
                // Saturate timer to prevent overflow
                if (ctl_timer_rwr_done) timer_d = timer_q;
                // Move on to RWR once B response sent
                b_valid_o = 1'b1;
                if (b_ready_i) state_d = WaitRWR;
            end
            WaitRWR: begin
                trx_cs_ena = 1'b0;
                if (ctl_timer_rwr_done) begin
                    state_d = ctl_tf_burst_done ? Idle : WaitCSS;
                end
            end
        endcase
    end

    // PHY state registers, including timer and transfer
    always_ff @(posedge clk_0_i or negedge rst_ni) begin : proc_ff_phy
        if (~rst_ni) begin
            state_q <= Idle;
            timer_q <= '0;
            tf_q    <= hyper_tf_t'{burst_type: 1'b1, default:'0};
            cs_q    <= '0;
        end else begin
            state_q <= state_d;
            timer_q <= timer_d;
            tf_q    <= tf_d;
            cs_q    <= cs_d;
        end
    end

endmodule
