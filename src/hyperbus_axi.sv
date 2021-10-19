// Hyperbus AXI

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// TODO: Cut path somewhere?

module hyperbus_axi #(
    parameter int unsigned AxiDataWidth  = -1,
    parameter int unsigned AxiAddrWidth  = -1,
    parameter int unsigned AxiIdWidth    = -1,
    parameter type         axi_req_t     = logic,
    parameter type         axi_rsp_t     = logic,
    parameter type         axi_w_chan_t  = logic,
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
    input  logic [4:0]              addr_mask_msb_i,
    input  logic                    addr_space_i,
    output logic                    trans_active_o
);

    localparam AxiDataBytes = AxiDataWidth/8;
    localparam ChipSelWidth = cf_math_pkg::idx_width(NumChips);
    localparam ByteCntWidth = cf_math_pkg::idx_width(AxiDataBytes);

    typedef logic [AxiAddrWidth-1:0] axi_addr_t;
    typedef logic [ByteCntWidth-1:0] byte_cnt_t;
    typedef logic [ByteCntWidth-3:0] word_cnt_t;
    typedef logic [AxiDataWidth-1:0] axi_data_t;
    typedef logic [ChipSelWidth-1:0] chip_sel_idx_t;

    // No need to track ID: serializer buffers it for us
    typedef struct packed {
        axi_addr_t          addr;
        axi_pkg::len_t      len;
        axi_pkg::burst_t    burst;
        axi_pkg::size_t     size;
    } axi_ax_t;

    typedef struct packed {
        logic               valid;
        axi_data_t          data;
        logic               error;
        logic               last;
    } axi_r_t;

    typedef struct packed {
        logic [7:0]         data;
        logic               strb;
    } axi_wbyte_t;

    // Atomics Filter downstream
    axi_req_t       atop_out_req;
    axi_rsp_t       atop_out_rsp;

    // ID serializer downstream
    axi_req_t       ser_out_req;
    axi_rsp_t       ser_out_rsp;
    axi_ax_t        ser_out_req_aw;
    axi_ax_t        ser_out_req_ar;

    // AX arbiter downstream
    axi_ax_t        rr_out_req_ax;
    logic           rr_out_req_write;

    // AX handling
    logic           trans_handshake;
    logic           ax_valid, ax_ready;
    axi_pkg::size_t ax_size_d, ax_size_q;
    logic           byte_last_even_d, byte_last_even_q;
    chip_sel_idx_t  ax_chip_sel_idx;
    logic           ax_size_byte;
    hyperbus_pkg::hyper_blen_t ax_blen_postinc;
    logic           ax_blen_inc;

    // R/W shared byte lane counter
    byte_cnt_t      byte_cnt_d, byte_cnt_q;
    byte_cnt_t      byte_offs_d, byte_offs_q;
    byte_cnt_t      byte_in_beat;
    logic           byte_cnt_odd;
    logic           word_cnt_odd;
    word_cnt_t      word_cnt;
    logic           endbeat;
   
    // R channel
    axi_r_t         r_buf_d, r_buf_q;
    logic           r_buf_ready;
    logic           endword_r;
    logic           splitted_r_valid;
    logic           s_last;
   
    // W channel spill
    axi_w_chan_t    w_spill, w_spill_buffer, w_spill_composed;
    logic           w_spill_valid, w_spill_ready;
    logic           w_spill_valid_buffer, w_spill_ready_buffer;
    logic           w_spill_valid_composed, w_spill_ready_composed;
    logic           first_tx_d, first_tx_q;
    logic           cnt_buffer_words_d, cnt_buffer_words_q;
    logic            sel_spill;
       
    // W channel
    axi_wbyte_t     w_buf_d, w_buf_q;
    logic [31:0]    w_sel_data;
    logic [3:0]     w_sel_strb;
    logic           endword_w;

    // Whether a transfer is currently active
    logic           trans_active_d, trans_active_q;
    logic           trans_active_set, trans_active_reset;
    logic           trans_wready_d, trans_wready_q;
    logic           trans_wready_set, trans_wready_reset;

    // ============================
    //    Serialize requests
    // ============================

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
        .req_o      ( ax_valid          ),
        .gnt_i      ( ax_ready          ),
        .data_o     ( rr_out_req_ax     ),
        .idx_o      ( rr_out_req_write  )
    );

    assign trans_valid_o    = ax_valid & ~trans_active_q;
    assign ax_ready         = trans_ready_i & ~trans_active_q;

    assign trans_handshake = trans_valid_o & trans_ready_i;

    // ============================
    //    AX channel: handle
    // ============================

    // Handle address mapping to chip select
    addr_decode #(
        .NoIndices  ( NumChips      ),
        .NoRules    ( NumChips      ),
        .addr_t     ( axi_addr_t    ),
        .rule_t     ( rule_t        )
    ) i_addr_decode_chip_sel (
        .addr_i             ( rr_out_req_ax.addr    ),
        .addr_map_i         ( chip_rules_i          ),
        .idx_o              ( ax_chip_sel_idx       ),
        .dec_valid_o        (  ),
        .dec_error_o        (  ),
        .en_default_idx_i   ( 1'b1                  ),
        .default_idx_i      ( '0                    )
    );

    // Chip select binary to one hot decoding
    always_comb begin : proc_comb_trans_cs
        trans_cs_o = '0;
        trans_cs_o[ax_chip_sel_idx] = 1'b1;
    end

    // Whether this is a byte-size transfer
    assign ax_size_byte = (ax_size_q == '0);

    // Remember properties of transfer that we will need (rest forwarded to PHY)
    always_comb begin : proc_comb_ax_buffer
        ax_size_d           = ax_size_q;
        byte_last_even_d    = byte_last_even_q;
        if (trans_handshake) begin
            ax_size_d           = rr_out_req_ax.size;
            byte_last_even_d    = ~rr_out_req_ax.len[0] ^ rr_out_req_ax.addr[0];
        end
    end

    // AX channel: forward, converting unmasked byte to masked word addresses
    assign trans_o.write            = rr_out_req_write;
    assign trans_o.burst_type       = 1'b1;             // Wrapping bursts not (yet) supported
    assign trans_o.address_space    = addr_space_i;
    assign trans_o.address          = (rr_out_req_ax.addr & ~32'(32'hFFFF_FFFF << addr_mask_msb_i)) >> ( 1 + 1 );
      
    // Convert burst length from decremented, unaligned beats to non-decremented, aligned 16-bit words
    always_comb begin
        if (rr_out_req_ax.size != '0) begin
            ax_blen_inc   = 1'b1;
            if ((rr_out_req_ax.size==1) && ax_blen_postinc[0]) begin
               trans_o.burst = (ax_blen_postinc << (rr_out_req_ax.size - 1)) + 1;
            end else begin
               trans_o.burst = (ax_blen_postinc << (rr_out_req_ax.size - 1)) + (rr_out_req_ax.addr[1]<<1);
            end
        end else begin
            ax_blen_inc = rr_out_req_ax.addr[0];
            trans_o.burst = (ax_blen_postinc >> 1) + 1;
        end
    end

    assign ax_blen_postinc = rr_out_req_ax.len + hyperbus_pkg::hyper_blen_t'(ax_blen_inc) ; 

    // ============================
    //    R/W byte counting
    // ============================

    // Counts base byte offset for current 16-bit window in data lanes
    always_comb begin : proc_comb_byte_cnt
        byte_cnt_d  = byte_cnt_q;
        byte_offs_d = byte_offs_q;
        if (trans_handshake) begin
            byte_cnt_d  = rr_out_req_ax.addr[ByteCntWidth-1:0];
            byte_offs_d = rr_out_req_ax.addr[ByteCntWidth-1:0];
        end else begin
            // 16-bit aligned: advance whenever downstream advances
            if ((tx_valid_o & tx_ready_i) | (rx_valid_i & rx_ready_o)) 
                  byte_cnt_d = byte_cnt_q + 4;
            // Byte offset: advance only for byte-size transfers whenever upstream advances
            if (ax_size_byte & ((w_spill_valid & w_spill_ready)
                    | (ser_out_rsp.r_valid & ser_out_req.r_ready)))
                byte_cnt_d[0]  = ~byte_cnt_q[0];
        end
    end

    // Byte offset in current beat, relative to (possibly unaligned) address offset
    assign byte_in_beat = byte_cnt_q - byte_offs_q;

    always_comb begin : proc_comb_endbeat
        // Size 0 (8b) and 1 (16b) transfers complete upstream beats in every handshaked cycle
        endbeat = 1'b1;
        for (int unsigned i=2; i < ax_size_q; ++i)
              endbeat &= byte_in_beat[i];
    end

    // Current word AND whether current byte pointer is on odd byte address
    assign {word_cnt, word_cnt_odd, byte_cnt_odd} = byte_cnt_q;
   
    // ============================
    //    R channel: coalesce
    // ============================

    // R channel pops beat (or two for bytes) from coalescing buffer as soon as it is valid
    assign ser_out_rsp.r.data   = r_buf_q.data;
    assign ser_out_rsp.r.last   = s_last ; //r_buf_q.last & endword_r & !s_mask_last;
    assign ser_out_rsp.r.resp   = r_buf_q.error ? axi_pkg::RESP_SLVERR : axi_pkg::RESP_OKAY;
    assign ser_out_rsp.r.id     = '0;
    assign ser_out_rsp.r.user   = '0;
//    assign ser_out_rsp.r_valid  = r_buf_q.valid ;
    assign ser_out_rsp.r_valid  = splitted_r_valid;

    hyperbus_splitter i_hyperbus_splitter (
        .clk_i,
        .rst_ni,
        .is_16_bw        ( ax_size_q == 1                             ),
        .trans_handshake ( trans_handshake                            ),
        .start_addr      ( rr_out_req_ax.addr[1]                      ),
        .last_addr       ( rr_out_req_ax.addr[1] ^ ax_blen_postinc[0] ),
        .last_i          ( r_buf_q.last                               ),
        .valid_i         ( r_buf_q.valid                              ),
        .valid_o         ( splitted_r_valid                           ),
        .last_o          ( s_last                                     ),
        .ready_i         ( ser_out_req.r_ready                        )
    );

    // Complete RX word if not byte-size transfer OR at every odd byte OR at last byte (if it has even index)
    assign endword_r = ~ax_size_byte | byte_cnt_odd | (rx_i.last & byte_last_even_q);

    assign r_buf_ready  = endword_r & ser_out_req.r_ready ;
    assign rx_ready_o   = ( ~r_buf_q.valid | r_buf_ready ) ;

    // Read-coalescing beat buffer: is marked valid once a beat is pushed on completion
    always_comb begin : proc_comb_r_buf
        r_buf_d = r_buf_q;
        // Pop: vacate old beat when it is valid and upstream is ready to consume data
        if (r_buf_q.valid & r_buf_ready) begin
            // TODO POWER @paulsc: unnecessary clear of data; valid suffices (but easier for debug)
            r_buf_d.valid = '0;
            r_buf_d.last = '0;
        end
        // Push: load new beat, onto cleared data if concurrent with pop
        if (rx_valid_i & rx_ready_o) begin
            r_buf_d.valid   = endbeat | rx_i.last;
            r_buf_d.error   = r_buf_q.error | rx_i.error;
            r_buf_d.last    = rx_i.last;
            r_buf_d.data[32*word_cnt +:32] = rx_i.data;
        end
    end

    // ============================
    //    W channel: Buffer
    // ============================

    spill_register #(
        .T      ( axi_w_chan_t ),
        .Bypass ( 0            )
    ) i_wchan_spill (
        .clk_i,
        .rst_ni,
        .data_i  ( ser_out_req.w        ),
        .valid_i ( ser_out_req.w_valid  ),
        .ready_o ( ser_out_rsp.w_ready  ),
        .data_o  ( w_spill_buffer       ),
        .valid_o ( w_spill_valid_buffer ),
        .ready_i ( w_spill_ready_buffer )
    );

    // ============================
    //    W channel : compose words
    // ============================

    hyperbus_upsizer # (
        .T      ( axi_w_chan_t )
    ) i_hyperbus_upsizer (
        .clk_i,
        .rst_ni,
        .is_16_bw  ( ax_size_q == 1         ),
        .sel_o     ( sel_spill              ),
        .first_tx  ( first_tx_q             ),
        .start_addr( word_cnt_odd           ),
        .data_i    ( w_spill_buffer         ),
        .valid_i   ( w_spill_valid_buffer   ),
        .ready_o   ( w_spill_ready_composed ),
        .data_o    ( w_spill_composed       ),
        .valid_o   ( w_spill_valid_composed ),
        .ready_i   ( w_spill_ready          )
    );
   
    assign w_spill              = ( sel_spill ) ? w_spill_buffer       : w_spill_composed;
    assign w_spill_valid        = ( sel_spill ) ? w_spill_valid_buffer : w_spill_valid_composed;
    assign w_spill_ready_buffer = ( sel_spill ) ? w_spill_ready        : w_spill_ready_composed;
    
    // ============================
    //    W channel: serialize
    // ============================

    assign tx_o.last = w_spill.last & endbeat;

    // Complete TX word if not byte-size transfer OR at every second byte OR at final byte:
    assign endword_w = ax_size_byte ? (byte_cnt_odd | w_spill.last) : 1'b1;

    assign tx_valid_o = trans_wready_q & w_spill_valid & endword_w;  // Uses lock-in on upstream W channel
    // We block the W channel until an AW was received (transfer is active and is a write).
    // To stay AXI compliant, we use a write channel spill register decoupling the W channel.
    // Downstream TX channel must be ready unless bufferable byte-size transfer
    assign w_spill_ready = trans_wready_q & (endbeat & (tx_ready_i | ~endword_w));

    // Select word window as byte-wrapping for unaligned accesses
    assign w_sel_data = w_spill.data[32*word_cnt +:32];
    assign w_sel_strb = w_spill.strb[ 4*word_cnt +: 4];

    // Assign downstream word to window
    always_comb begin : proc_comb_w_coalesce
        tx_o.data = w_sel_data;
        tx_o.strb = w_sel_strb;
        if (ax_size_byte) begin
            if (word_cnt_odd) begin
               if (byte_cnt_odd) begin
                   // On odd byte: overlay previous byte if in byte-size transfer
                   tx_o.data[23:16]  = w_buf_q.data;
                   tx_o.strb[2]      = w_buf_q.strb;
               end else begin
                   // On even byte: masks out upper strobe
                   tx_o.strb[0]      = 1'b0;
                   tx_o.strb[1]      = 1'b0;
                   tx_o.strb[3]      = 1'b0;
               end
            end else begin
               if (byte_cnt_odd) begin
                   // On odd byte: overlay previous byte if in byte-size transfer
                   tx_o.data[7:0]  = w_buf_q.data;
                   tx_o.strb[0]    = w_buf_q.strb;
               end else begin
                   // On even byte: masks out upper strobe
                   tx_o.strb[1]    = 1'b0;
                   tx_o.strb[2]    = 1'b0;
                   tx_o.strb[3]    = 1'b0;
               end
             end    
        end
    end

    // Buffer lower byte and its strobe for byte-size transfer when necessary
    always_comb begin : proc_comb_w_buffer
        w_buf_d = w_buf_q;
        if (w_spill_valid & w_spill_ready & ax_size_byte & ~byte_cnt_odd) begin
            w_buf_d.data = w_sel_data[7:0];
            w_buf_d.strb = w_sel_strb[0];
        end else if (trans_handshake) begin
            // TODO POWER @paulsc: unnecessary clear of data; strb suffices (but easier for debug)
            w_buf_d = '0;       // Reset buffer new transfer begins (in case of odd upbeat)
        end
    end

    // ============================
    //    B channel: passthrough
    // ============================

    assign ser_out_rsp.b.resp   = b_error_i ? axi_pkg::RESP_SLVERR : axi_pkg::RESP_OKAY;
    assign ser_out_rsp.b.user   = '0;
    assign ser_out_rsp.b.id     = '0;
    assign ser_out_rsp.b_valid  = b_valid_i;
    assign b_ready_o            = ser_out_req.b_ready;

    // ============================
    //    Transfer status
    // ============================

    assign trans_active_o = trans_active_q;

    assign trans_active_set     = trans_handshake;
    assign trans_active_reset   = (rx_valid_i & rx_ready_o & rx_i.last) | (b_valid_i & b_ready_o);

    // Allow W transfers iff currently engaged in write (AW already received)
    assign trans_wready_set     = trans_active_set & rr_out_req_write;
    assign trans_wready_reset   = (tx_valid_o & tx_ready_i & tx_o.last);

    // Set overrules reset as a transfer must start before it finishes
    always_comb begin : proc_comb_trans_active
        trans_active_d = trans_active_q;
        trans_wready_d = trans_wready_q;
        if (trans_active_reset) trans_active_d = 1'b0;
        if (trans_active_set)   trans_active_d = 1'b1;
        if (trans_wready_reset) trans_wready_d = 1'b0;
        if (trans_wready_set)   trans_wready_d = 1'b1;
    end

    // Set overrules reset as a transfer must start before it finishes
    always_comb begin : proc_comb_is_first_tx
        first_tx_d = first_tx_q;
        if (trans_handshake) first_tx_d = 1'b1;
        if (tx_valid_o & tx_ready_i)  first_tx_d = 1'b0;
    end

    // =========================
    //    Registers
    // =========================

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff
        if(~rst_ni) begin
            ax_size_q           <= '0;
            byte_last_even_q    <= '0;
            byte_cnt_q          <= '0;
            byte_offs_q         <= '0;
            r_buf_q             <= '0;
            w_buf_q             <= '0;
            trans_active_q      <= '0;
            trans_wready_q      <= '0;
            first_tx_q          <= '0;
        end else begin
            ax_size_q           <= ax_size_d;
            byte_last_even_q    <= byte_last_even_d;
            byte_cnt_q          <= byte_cnt_d;
            byte_offs_q         <= byte_offs_d;
            r_buf_q             <= r_buf_d;
            w_buf_q             <= w_buf_d;
            trans_active_q      <= trans_active_d;
            trans_wready_q      <= trans_wready_d;
            first_tx_q          <= first_tx_d;
        end
    end

    // =========================
    //    Assertions
    // =========================

    // pragma translate_off
    `ifndef VERILATOR
    initial assert (AxiDataWidth >= 16 && AxiDataWidth <= 1024)
            else $error("AxiDatawidth must be a power of two within [16, 1024].");

    read_endbeat_align : assert property(
      @(posedge clk_i) rx_valid_i & rx_ready_o & rx_i.last |-> endbeat)
        else $fatal (1, "Last word of read should be aligned with transfer size.");

    access_16b_align : assert property(
      @(posedge clk_i) trans_handshake & (rr_out_req_ax.size != '0) |-> (rr_out_req_ax.addr[0] == 1'b0))
        else $fatal (1, "The address of a non-byte-size access must be 2-byte aligned.");

    burst_type : assert property(
      @(posedge clk_i) trans_handshake |-> rr_out_req_ax.burst == axi_pkg::BURST_INCR)
        else $fatal (1, "Non-incremental burst passed; this is currently not supported.");
    `endif
    // pragma translate_on

endmodule
