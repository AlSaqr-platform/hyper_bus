// Hyperbus AXI

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"

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

    input hyperbus_pkg::hyper_b_t   b_i,
    input  logic                    b_valid_i,
    output logic                    b_ready_o,

    output hyperbus_pkg::hyper_tf_t trans_o,
    output logic [NumChips-1:0]     trans_cs_o,
    output logic                    trans_valid_o,
    input  logic                    trans_ready_i,
    // Chip address ranges
    input rule_t [NumChips-1:0]     chip_rules_i
);

    localparam ChipSelWidth = cf_math_pkg::idx_width(NumChips);

    // create axi structs
    localparam int unsigned NarrowDataWidth = 16;

    typedef logic [AxiAddrWidth-1:0]      axi_addr_t;
    typedef logic [AxiDataWidth-1:0]      axi_data_t;
    typedef logic [AxiDataWidth/8-1:0]    axi_strb_t;
    typedef logic [AxiIdWidth-1:0]        axi_id_t;
    typedef logic [NarrowDataWidth-1:0]   narrow_data_t;
    typedef logic [NarrowDataWidth/8-1:0] narrow_strb_t;

    // ar
    `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, axi_addr_t, axi_id_t, logic [0:0])
    // r
    `AXI_TYPEDEF_W_CHAN_T(axi_w_chan_t, axi_data_t, axi_strb_t, logic [0:0])
    `AXI_TYPEDEF_W_CHAN_T(narrow_w_chan_t, narrow_data_t, narrow_strb_t, logic [0:0])
    // b
    `AXI_TYPEDEF_B_CHAN_T(b_chan_t, axi_id_t, logic [0:0])
    // ar
    `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, axi_addr_t, axi_id_t, logic [0:0])
    // r
    `AXI_TYPEDEF_R_CHAN_T(axi_r_chan_t, axi_data_t, axi_id_t, logic [0:0])
    `AXI_TYPEDEF_R_CHAN_T(narrow_r_chan_t, narrow_data_t, axi_id_t, logic [0:0])
    // narrow port
    `AXI_TYPEDEF_REQ_T(narrow_req_t, aw_chan_t, narrow_w_chan_t, ar_chan_t)
    `AXI_TYPEDEF_RESP_T(narrow_rsp_t, b_chan_t, narrow_r_chan_t)

    // create a narrow axi bus
    narrow_req_t  narrow_req;
    narrow_rsp_t narrow_rsp;

    // the phy needs information about the read address, burst length, and burst type.
    // create a struct holding the information and arbitrating over it
    typedef struct packed {
        axi_addr_t       addr;
        axi_id_t         id;
        axi_pkg::len_t   burst_len;
        axi_pkg::burst_t burst_type;
    } axi_hyp_ax_tf_t;

    axi_hyp_ax_tf_t axi_hyp_ar_tf, axi_hyp_aw_tf, axi_hyp_rr_tf;


    // internally: use a 16 bit AXI bus to towards the hyperbus macro
    axi_dw_converter #(
        .AxiMaxReads            ( 1                   ), // TODO: tune
        .AxiSlvPortDataWidth    ( AxiDataWidth        ),
        .AxiMstPortDataWidth    ( NarrowDataWidth     ),
        .AxiAddrWidth           ( AxiAddrWidth        ),
        .AxiIdWidth             ( AxiIdWidth          ),
        .aw_chan_t              ( aw_chan_t           ),
        .mst_w_chan_t           ( narrow_w_chan_t     ),
        .slv_w_chan_t           ( axi_w_chan_t        ),
        .b_chan_t               ( b_chan_t            ),
        .ar_chan_t              ( ar_chan_t           ),
        .mst_r_chan_t           ( narrow_r_chan_t     ),
        .slv_r_chan_t           ( axi_r_chan_t        ),
        .axi_mst_req_t          ( narrow_req_t        ),
        .axi_mst_resp_t         ( narrow_rsp_t        ),
        .axi_slv_req_t          ( axi_req_t           ),
        .axi_slv_resp_t         ( axi_rsp_t           )
    ) i_axi_dw_converter (
        .clk_i                  ( clk_i               ),
        .rst_ni                 ( rst_ni              ),
        .slv_req_i              ( axi_req_i           ),
        .slv_resp_o             ( axi_rsp_o           ),
        .mst_req_o              ( narrow_req          ),
        .mst_resp_i             ( narrow_rsp          )
    );

    // feed arbiter with data from ar and aw channels
    assign axi_hyp_aw_tf.addr       = narrow_req.aw.addr;
    assign axi_hyp_aw_tf.burst_len  = narrow_req.aw.len;
    assign axi_hyp_aw_tf.burst_type = narrow_req.aw.burst;
    assign axi_hyp_aw_tf.id         = narrow_req.aw.id;

    assign axi_hyp_ar_tf.addr       = narrow_req.ar.addr;
    assign axi_hyp_ar_tf.burst_len  = narrow_req.ar.len;
    assign axi_hyp_ar_tf.burst_type = narrow_req.ar.burst;
    assign axi_hyp_ar_tf.id         = narrow_req.ar.id;

    // we use the rr arb tree to arbitrate between reads and writes
    rr_arb_tree #(
        .NumIn     ( 32'd2            ),
        .DataType  ( axi_hyp_ax_tf_t  ),
        .AxiVldRdy ( 1'b1             ),
        .LockIn    ( 1'b1             )
    ) i_rr_arb_tree (
        .clk_i     ( clk_i            ),
        .rst_ni    ( rst_ni           ),
        .flush_i   ( 1'b0             ),
        .rr_i      ( '0               ),
        .req_i     ( {narrow_req.aw_valid, narrow_req.ar_valid }    ),
        .gnt_o     ( {narrow_rsp.aw_ready, narrow_rsp.ar_ready }    ),
        .data_i    ( {axi_hyp_aw_tf,       axi_hyp_ar_tf       }    ),
        .gnt_i     ( trans_ready_i                                  ),
        .req_o     ( trans_valid_o                                  ),
        .data_o    ( axi_hyp_rr_tf                                  ),
        .idx_o     ( trans_write_o                                  )
    );

    // assign arbitrated output to phy
    assign trans_o.address       = axi_hyp_rr_tf.addr;
    assign trans_o.burst         = axi_hyp_rr_tf.burst_len;
    assign trans_o.burst_type    = axi_hyp_rr_tf.burst_type[0];
    assign trans_o.address_space = axi_hyp_rr_tf.addr[AxiAddrWidth-1];

    // connect the w channel
    assign tx_o.data          = narrow_req.w.data;
    assign tx_o.strb          = narrow_req.w.strb;
    assign tx_valid_o         = narrow_req.w_valid;
    assign narrow_rsp.w_ready = tx_ready_i;

    // connect the r channel
    assign narrow_rsp.r.id    = axi_hyp_rr_tf.id;
    assign narrow_rsp.r.data  = rx_i.data;
    assign narrow_rsp.r.last  = rx_i.last;
    assign narrow_rsp.r.resp  = rx_i.error ? axi_pkg::RESP_SLVERR : axi_pkg::RESP_OKAY;
    assign narrow_rsp.r.user  = 1'b0;
    assign narrow_rsp.r_valid = rx_valid_i;
    assign rx_ready_o         = narrow_req.r_ready;

    // connect the b channel
    assign narrow_rsp.b.id    = axi_hyp_rr_tf.id;
    assign narrow_rsp.b.resp  = b_i.error ? axi_pkg::RESP_SLVERR : axi_pkg::RESP_OKAY;
    assign narrow_rsp.b.user  = 1'b0;
    assign narrow_rsp.b_valid = b_valid_i & b_i.last;
    assign b_ready_o          = narrow_req.b_ready;

    // handle address mapping to chip select -> one hot
    logic [ChipSelWidth-1:0] chip_sel_idx;
    addr_decode #(
        .NoIndices       ( NumChips             ),
        .NoRules         ( NumChips             ),
        .addr_t          ( axi_addr_t           ),
        .rule_t          ( rule_t               )
    ) i_addr_decode_chip_sel (
        .addr_i          ( axi_hyp_rr_tf.addr   ),
        .addr_map_i      ( chip_rules_i         ),
        .idx_o           ( chip_sel_idx         ),
        .dec_valid_o     ( ),
        .dec_error_o     ( ),
        .en_default_idx_i( 1'b1                 ),
        .default_idx_i   ( '0                   )
    );

    // chip sel binary to one hot decoding
    always_comb begin : proc_bin_to_onehot
        trans_cs_o               = '0;
        trans_cs_o[chip_sel_idx] = 1'b1;
    end

endmodule

