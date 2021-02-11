// Hyperbus AXI

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// TODO: Cut path somewhere?
// TODO: Are unaligned narrow transfers / burst starts _really_ internally unaligned? if so, they will not work :S

module hyperbus_axi #(
    parameter int unsigned AxiDataWidth  = -1,
    parameter int unsigned AxiAddrWidth  = -1,
    parameter int unsigned AxiIdWidth    = -1,
    parameter type         axi_req_t     = logic,
    parameter type         axi_rsp_t     = logic,
    parameter int unsigned NumChips    	 = -1,
    parameter type         rule_t        = logic
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    // AXI port
    input  axi_req_t                axi_req_i,
    output axi_rsp_t                axi_rsp_o,
    // PHI port
    input  hyperbus_pkg::hyper_rx_t rx_i,
    input  logic                    rx_valid_i,
    output logic                    rx_ready_o,

    output hyperbus_pkg::hyper_tx_t tx_o,
    output logic                    tx_valid_o,
    input  logic                    tx_ready_i,

    input  logic                    b_error_i,
    input  logic                    b_valid_i,
    output logic                    b_ready_o,

    output hyperbus_pkg::hyper_tf_t trans_o,
    output logic [NumChips-1:0]     trans_cs_o,
    output logic                    trans_valid_o,
    input  logic                    trans_ready_i,

    input  rule_t [NumChips-1:0]    chip_rules_i,
    input  logic                    addr_space_i
);

    localparam WordsPerBeat = AxiDataWidth/16;
    localparam ChipSelWidth = cf_math_pkg::idx_width(NumChips);
    localparam WordCntWidth = cf_math_pkg::idx_width(WordsPerBeat);

    typedef logic [AxiAddrWidth-1:0] axi_addr_t;
    typedef logic [WordCntWidth-1:0] word_cnt_t;
    typedef logic [AxiDataWidth-2:0] axi_data_t;

    // No need to track ID: serializer buffers it for us
    typedef struct packed {
        axi_addr_t          addr;
        axi_pkg::len_t      len;
        axi_pkg::burst_t    burst;
        axi_pkg::size_t     size;
    } axi_ax_t;

    axi_req_t   atop_out_req;
    axi_rsp_t   atop_out_rsp;

    axi_req_t   ser_out_req;
    axi_rsp_t   ser_out_rsp;

    axi_ax_t    ser_out_req_aw;
    axi_ax_t    ser_out_req_ar;

    axi_data_t  r_data_d, r_data_q;
    logic       r_error_d, r_error_q;

    word_cnt_t  lane_cnt_d, lane_cnt_q;
    logic       lane_cnt_endbeat;

    logic [7:0] w_byte_d, w_byte_q;
    logic       w_strb_d, w_strb_q;

    logic       lane_boffs_d, lane_boffs_q;
    logic       boffs_cnt_last;

    axi_ax_t    rr_out_req_ax;
    logic       rr_out_req_write;

    axi_pkg::size_t curr_ax_size_d, curr_ax_size_q;
    logic           curr_ax_size_byte;

    // Block unsupported atomics
    axi_atop_filter #(
        .AxiIdWidth         ( AxiIdWidth    ),
        .AxiMaxWriteTxns    ( 1             ),
        .req_t              ( axi_req_t     ),
        .resp_t             ( axi_rsp_t     )
    ) i_axi_atop_filter (
        .clk_i,
        .rst_ni,
        .slv_req_i  ( axi_req_i     ),
        .slv_resp_o ( axi_rsp_o     ),
        .mst_req_o  ( atop_out_req  ),
        .mst_resp_i ( atop_out_rsp  )
    );

    // Ensure we only handle one ID (master) at a time
    axi_serializer #(
        .MaxReadTxns    ( 1             ),
        .MaxWriteTxns   ( 1             ),
        .AxiIdWidth     ( AxiIdWidth    ),
        .req_t          ( axi_req_t     ),
        .resp_t         ( axi_rsp_t     )
    ) i_axi_serializer (
        .clk_i,
        .rst_ni,
        .slv_req_i  ( atop_out_req  ),
        .slv_resp_o ( atop_out_rsp  ),
        .mst_req_o  ( ser_out_req   ),
        .mst_resp_i ( ser_out_rsp   )
    );

    // W channel: size downconversion
    assign tx_o.last            = ser_out_req.w.last & (lane_cnt_endbeat | boffs_cnt_last);
    assign tx_valid_o           = (ser_out_req.w.last | boffs_cnt_last) & ser_out_req.w_valid;  // Use lock-in: data valid until handshaked
    assign ser_out_rsp.w_ready  = lane_cnt_endbeat & (~boffs_cnt_last | tx_ready_i);            // Ready if coalescing buffer is or upstream

    always_comb begin : proc_comb_w_coalesce
        tx_o.data = ser_out_req.w.data[16*lane_cnt_q+:16];
        tx_o.strb = ser_out_req.w.strb[ 2*lane_cnt_q+: 2];
        if (curr_ax_size_byte & boffs_cnt_last) begin
            tx_o.data[7:0]  = w_byte_q;       // Overlay previous byte if in byte transfer
            tx_o.strb[0]    = w_strb_q;
        end
    end

    always_comb begin : proc_comb_w_buffer
        w_byte_d = w_byte_q;
        w_strb_d = w_strb_q;
        if (ser_out_req.w_valid & ser_out_rsp.w_ready & curr_ax_size_byte & ~boffs_cnt_last) begin
            w_byte_d = ser_out_req.w.data[7:0];             // Buffer lower byte for size 0 xfer if necessary
            w_strb_d = ser_out_req.w.strb[0];               // Also buffer corresponding strobe
        end else if (trans_valid_o & trans_ready_i) begin
            w_strb_d = 1'b0;                                // Reset buffered strobe when new transfer begins
        end
    end

    // B channel: 1-to-1-connection
    assign ser_out_rsp.b.resp   = b_error_i ? axi_pkg::RESP_SLVERR : axi_pkg::RESP_OKAY;
    assign ser_out_rsp.b.user   = '0;
    assign ser_out_rsp.b.id     = '0;
    assign ser_out_rsp.b_valid  = b_valid_i;
    assign b_ready_o            = ser_out_req.b_ready;

    // R channel: size upconversion
    assign ser_out_rsp.r.last   = rx_i.last;
    assign ser_out_rsp.r.resp   = (r_error_q | rx_i.error) ? axi_pkg::RESP_SLVERR : axi_pkg::RESP_OKAY;
    assign ser_out_rsp.r.id     = '0;
    assign ser_out_rsp.r.user   = '0;
    assign ser_out_rsp.r_valid  = lane_cnt_endbeat & rx_valid_i;            // Use lock-in: data valid until handshaked
    assign rx_ready_o           = ~lane_cnt_endbeat | ser_out_req.r_ready;  // Ready if coalescing buffer is or upstream

    always_comb begin : proc_comb_r_error
        r_error_d = r_error_q;
        if      (lane_cnt_endbeat)          r_error_d = 1'b0;
        else if (rx_valid_i & rx_ready_o)   r_error_d = r_error_q | rx_i.error;
    end

    always_comb begin : proc_comb_r_coalesce
        ser_out_rsp.r.data = r_data_q;
        ser_out_rsp.r.data[16*lane_cnt_q+:16] = rx_i.data;   // Forward last word in beat directly to master
    end

    always_comb begin : proc_comb_r_buffer
        r_data_d = r_data_q;
        if (rx_valid_i & rx_ready_o & ~lane_cnt_endbeat)
            r_data_d[16*lane_cnt_q+:16] = rx_i.data;         // Buffer words as they come in, except if forwarded
    end

    // Round-robin-arbitrate between AR and AW channels (HyperBus is simplex)
    assign ser_out_req_ar.addr  = ser_out_req.ar.addr;
    assign ser_out_req_ar.len   = ser_out_req.ar.len;
    assign ser_out_req_ar.burst = ser_out_req.ar.burst;
    assign ser_out_req_ar.size  = ser_out_req.ar.size;

    assign ser_out_req_aw.addr  = ser_out_req.aw.addr;
    assign ser_out_req_aw.len   = ser_out_req.aw.len;
    assign ser_out_req_aw.burst = ser_out_req.aw.burst;
    assign ser_out_req_aw.size  = ser_out_req.aw.size;

    rr_arb_tree #(
        .NumIn      ( 2         ),
        .DataType   ( axi_ax_t  ),
        .AxiVldRdy  ( 1         ),
        .LockIn     ( 1         )
    ) i_rr_arb_tree_ax (
        .clk_i,
        .rst_ni,
        .flush_i    ( 1'b0              ),
        .rr_i       ( '0                ),
        .req_i      ( { ser_out_req.aw_valid, ser_out_req.ar_valid } ),
        .gnt_o      ( { ser_out_rsp.aw_ready, ser_out_rsp.ar_ready } ),
        .data_i     ( { ser_out_req_aw,       ser_out_req_ar       } ),
        .req_o      ( trans_valid_o     ),
        .gnt_i      ( trans_ready_i     ),
        .data_o     ( rr_out_req_ax     ),
        .idx_o      ( rr_out_req_write  )
    );

    // Buffer size of transfer (rest is buffered in PHY)
    assign curr_ax_size_d       = (trans_valid_o & trans_ready_i) ? rr_out_req_ax.size : curr_ax_size_q;
    assign curr_ax_size_byte    = (curr_ax_size_q == '0);

    // Conversion lane and byte counter
    always_comb begin : proc_comb_lane_cnt
        lane_cnt_d = lane_cnt_q;
        lane_boffs_d = lane_boffs_q;
        if (trans_valid_o & trans_ready_i)
            {lane_cnt_d, lane_boffs_d} = rr_out_req_ax.addr[WordCntWidth:0];
        else begin
            if ((tx_valid_o & tx_ready_i) | (rx_valid_i & rx_ready_o))
                lane_cnt_d = lane_cnt_q + 1;
            if (curr_ax_size_byte & ((ser_out_req.w_valid & ser_out_rsp.w_ready) | (ser_out_rsp.r_valid & ser_out_req.r_ready))) begin
                lane_boffs_d = lane_boffs_q + 1;
            end
        end
    end

    // Conversion beat endings
    always_comb begin : proc_comb_endbeat
        lane_cnt_endbeat = 1'b1;
        if (~curr_ax_size_byte & (curr_ax_size_q != 1)) begin
            for (int unsigned i=0; i<curr_ax_size_q-1; ++i)
                lane_cnt_endbeat &= lane_cnt_q[i];
        end
    end

    // Conversion word endings: only split words for byte transfers
    assign boffs_cnt_last = curr_ax_size_byte ? lane_boffs_q : 1'b1;

    // Handle address mapping to chip select
    logic [ChipSelWidth-1:0] chip_sel_idx;
    addr_decode #(
        .NoIndices  ( NumChips      ),
        .NoRules    ( NumChips      ),
        .addr_t     ( axi_addr_t    ),
        .rule_t     ( rule_t        )
    ) i_addr_decode_chip_sel (
        .addr_i             ( rr_out_req_ax.addr    ),
        .addr_map_i         ( chip_rules_i          ),
        .idx_o              ( chip_sel_idx          ),
        .dec_valid_o        (  ),
        .dec_error_o        (  ),
        .en_default_idx_i   ( 1'b1                  ),
        .default_idx_i      ( '0                    )
    );

    // chip sel binary to one hot decoding
    always_comb begin : proc_comb_trans_cs
        trans_cs_o               = '0;
        trans_cs_o[chip_sel_idx] = 1'b1;
    end

    // AX channel: forward
    assign trans_o.write            = rr_out_req_write;
     // TODO: ADAPT DO DECREMENTED AXI STYLE? PHY ASSUMES BURST COUNT NOT DECREMENTED!!!!
    assign trans_o.burst            = (((hyperbus_pkg::hyper_blen_t'(rr_out_req_ax.len) + 1)) << ( (rr_out_req_ax.size == '0) ? '0 :  rr_out_req_ax.size-1));
    assign trans_o.burst_type       = rr_out_req_ax.burst[0];   // TODO: Implement wrapping bursts or tie to 0
    assign trans_o.address_space    = addr_space_i;
    assign trans_o.address          = rr_out_req_ax.addr >> 1;       // TODO: Handle overlaps with chip rules? TODO: MOVE SHIFT TO PHY

    // Registers
    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff_r
        if(~rst_ni) begin
            r_error_q       <= 1'b0;
            r_data_q        <= '0;
            lane_cnt_q      <= '0;
            curr_ax_size_q  <= 'h1;
            w_byte_q        <= '0;
            w_strb_q        <= 1'b0;
            lane_boffs_q    <= 1'b0;
        end else begin
            r_error_q       <= r_error_d;
            r_data_q        <= r_data_d;
            lane_cnt_q      <= lane_cnt_d;
            curr_ax_size_q  <= curr_ax_size_d;
            w_byte_q        <= w_byte_d;
            w_strb_q        <= w_strb_d;
            lane_boffs_q    <= lane_boffs_q;
        end
    end

    // pragma translate_off
    `ifndef VERILATOR
    initial assert (AxiDataWidth >= 16 && AxiDataWidth <= 1024)
            else $error("AxiDatawidth must be a power of two within [16, 1024].");

    read_size_align : assert property(
      @(posedge clk_i) rx_valid_i & rx_ready_o & rx_i.last |-> lane_cnt_endbeat)
        else $fatal (1, "Last word of read should be aligned with transfer size.");

    // TODO: Below assertions are due to WIP implementation and may be removed later
    burst_type : assert property(
      @(posedge clk_i) trans_valid_o & trans_ready_i |-> rr_out_req_ax.burst == axi_pkg::BURST_INCR)
        else $fatal (1, "Non-incremental burst passed; this is currently not supported.");
    `endif
    // pragma translate_on

endmodule
