// Hyperbus AXI

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <paulsc@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Contributor: Luca Valente <luca.valente@unibo.it>

module hyperbus_with_pads #(
    parameter int unsigned  NumChips        = -1,
    parameter int unsigned  NumPhys         = 2,
    parameter int unsigned  IsClockODelayed = 0,
    parameter int unsigned  L2_AWIDTH_NOAL  = 12,
    parameter int unsigned  TRANS_SIZE      = 16,
    parameter int unsigned  NB_CH           = 1,
    parameter int unsigned  AxiAddrWidth    = -1,
    parameter int unsigned  AxiDataWidth    = -1,
    parameter int unsigned  AxiIdWidth      = -1,
    parameter type          axi_req_t       = logic,
    parameter type          axi_rsp_t       = logic,
    parameter type          axi_w_chan_t    = logic,
    parameter int unsigned  RegAddrWidth    = -1,
    parameter int unsigned  RegDataWidth    = -1,
    parameter type          reg_req_t       = logic,
    parameter type          reg_rsp_t       = logic,
    parameter type          axi_rule_t      = logic,
    // The below have sensible defaults, but should be set on integration!
    parameter int unsigned  RxFifoLogDepth  = 2,
    parameter int unsigned  TxFifoLogDepth  = 2,
    parameter logic [RegDataWidth-1:0] RstChipBase  = 'h0,      // Base address for all chips
    parameter logic [RegDataWidth-1:0] RstChipSpace = 'h1_0000, // 64 KiB: Current maximum HyperBus device size
    parameter int unsigned  PhyStartupCycles = 300 /*us*/ * 200 /*MHz*/ // Conservative maximum frequency estimate
) (
    input  logic                        clk_phy_i,
    input  logic                        rst_phy_ni,
    input  logic                        clk_sys_i,
    input  logic                        rst_sys_ni,
    input  logic                        test_mode_i,
    // AXI bus
    input  axi_req_t                    axi_req_i,
    output axi_rsp_t                    axi_rsp_o,
    // Reg bus
    input  reg_req_t                    reg_req_i,
    output reg_rsp_t                    reg_rsp_o,
    // UDMA interface
    input  logic [31:0]                 cfg_data_i,
    input  logic [4:0]                  cfg_addr_i,
    input  logic [NB_CH:0]              cfg_valid_i,
    input  logic                        cfg_rwn_i,
    output logic [NB_CH:0]              cfg_ready_o,
    output logic [NB_CH:0][31:0]        cfg_data_o,

    output logic [L2_AWIDTH_NOAL-1:0]   cfg_rx_startaddr_o,
    output logic     [TRANS_SIZE-1:0]   cfg_rx_size_o,
    output logic                        cfg_rx_continuous_o,
    output logic                        cfg_rx_en_o,
    output logic                        cfg_rx_clr_o,
    input  logic                        cfg_rx_en_i,
    input  logic                        cfg_rx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0]   cfg_rx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0]   cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0]   cfg_tx_startaddr_o,
    output logic     [TRANS_SIZE-1:0]   cfg_tx_size_o,
    output logic                        cfg_tx_continuous_o,
    output logic                        cfg_tx_en_o,
    output logic                        cfg_tx_clr_o,
    input  logic                        cfg_tx_en_i,
    input  logic                        cfg_tx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0]   cfg_tx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0]   cfg_tx_bytes_left_i,
    output logic          [NB_CH-1:0]   evt_eot_hyper_o,
    output logic                        data_tx_req_o,
    input  logic                        data_tx_gnt_i,
    output logic                [1:0]   data_tx_datasize_o,
    input  logic               [31:0]   data_tx_i,
    input  logic                        data_tx_valid_i,
    output logic                        data_tx_ready_o,
    output logic                [1:0]   data_rx_datasize_o,
    output logic               [31:0]   data_rx_o,
    output logic                        data_rx_valid_o,
    input  logic                        data_rx_ready_i,

    // PHY interface
    inout  [NumPhys-1:0][NumPhys-1:0]   pad_hyper_csn,
    inout  [NumPhys-1:0]                pad_hyper_ck,
    inout  [NumPhys-1:0]                pad_hyper_ckn,
    inout  [NumPhys-1:0]                pad_hyper_rwds,
    inout  [NumPhys-1:0]                pad_hyper_reset,
    inout  [NumPhys-1:0][7:0]           pad_hyper_dq

);

   
    wire  [NumPhys-1:0][1:0] hyper_cs_n_wire;
    wire  [NumPhys-1:0]      hyper_ck_wire;
    wire  [NumPhys-1:0]      hyper_ck_n_wire;
    wire  [NumPhys-1:0]      hyper_rwds_o;
    wire  [NumPhys-1:0]      hyper_rwds_i;
    wire  [NumPhys-1:0]      hyper_rwds_oe;
    wire  [NumPhys-1:0][7:0] hyper_dq_i;
    wire  [NumPhys-1:0][7:0] hyper_dq_o;
    wire  [NumPhys-1:0]      hyper_dq_oe;
    wire  [NumPhys-1:0]      hyper_reset_n_wire;
             
    hyperbus #(
        .NumChips       ( NumChips        ),
        .NumPhys        ( NumPhys         ),
        .AxiAddrWidth   ( AxiAddrWidth    ),
        .AxiDataWidth   ( AxiDataWidth    ),
        .AxiIdWidth     ( AxiIdWidth      ),
        .axi_req_t      ( axi_req_t       ),
        .axi_rsp_t      ( axi_rsp_t       ),
        .axi_w_chan_t   ( axi_w_chan_t    ),
        .RegAddrWidth   ( RegAddrWidth    ),
        .RegDataWidth   ( RegDataWidth    ),
        .reg_req_t      ( reg_req_t       ),
        .reg_rsp_t      ( reg_rsp_t       ),
        .IsClockODelayed( IsClockODelayed ),
        .NB_CH          ( NB_CH           ),
        .axi_rule_t     ( axi_rule_t      )
    ) i_hyperbus (
        .clk_phy_i              ( clk_phy_i             ),
        .rst_phy_ni             ( rst_phy_ni            ),
        .clk_sys_i              ( clk_sys_i             ),
        .rst_sys_ni             ( rst_sys_ni            ),
        .test_mode_i            ( test_mode_i           ),
        .axi_req_i              ( axi_req_i             ),
        .axi_rsp_o              ( axi_rsp_o             ),
        .reg_req_i              ( reg_req_i             ),
        .reg_rsp_o              ( reg_rsp_o             ),

        .data_rx_o              ( data_rx_o             ),
        .data_rx_valid_o        ( data_rx_valid_o       ),
        .data_rx_ready_i        ( data_rx_ready_i       ),
        
        .data_tx_i              ( data_tx_i             ),
        .data_tx_valid_i        ( data_tx_valid_i       ),
        .data_tx_ready_o        ( data_tx_ready_o       ),
        .data_tx_gnt_i          ( data_tx_gnt_i         ),
        .data_tx_req_o          ( data_tx_req_o         ),
        
        .cfg_data_i             ( cfg_data_i            ),
        .cfg_addr_i             ( cfg_addr_i            ),
        .cfg_valid_i            ( cfg_valid_i           ),
        .cfg_rwn_i              ( cfg_rwn_i             ),
        .cfg_data_o             ( cfg_data_o            ),
        .cfg_ready_o            ( cfg_ready_o           ),
        
        .cfg_rx_startaddr_o     ( cfg_rx_startaddr_o    ),
        .cfg_rx_size_o          ( cfg_rx_size_o         ),
        .data_rx_datasize_o     ( data_rx_datasize_o    ),
        .cfg_rx_continuous_o    ( cfg_rx_continuous_o   ),
        .cfg_rx_en_o            ( cfg_rx_en_o           ),
        .cfg_rx_clr_o           ( cfg_rx_clr_o          ),
        .cfg_rx_en_i            ( cfg_rx_en_i           ),
        .cfg_rx_pending_i       ( cfg_rx_pending_i      ),
        .cfg_rx_curr_addr_i     ( cfg_rx_curr_addr_i    ),
        .cfg_rx_bytes_left_i    ( cfg_rx_bytes_left_i   ),
        
        .cfg_tx_startaddr_o     ( cfg_tx_startaddr_o    ),
        .cfg_tx_size_o          ( cfg_tx_size_o         ),
        .data_tx_datasize_o     ( data_tx_datasize_o    ),
        .cfg_tx_continuous_o    ( cfg_tx_continuous_o   ),
        .cfg_tx_en_o            ( cfg_tx_en_o           ),
        .cfg_tx_clr_o           ( cfg_tx_clr_o          ),
        .cfg_tx_en_i            ( cfg_tx_en_i           ),
        .cfg_tx_pending_i       ( cfg_tx_pending_i      ),
        .cfg_tx_curr_addr_i     ( cfg_tx_curr_addr_i    ),
        .cfg_tx_bytes_left_i    ( cfg_tx_bytes_left_i   ),

        .evt_eot_hyper_o        ( evt_eot_hyper_o       ),
             
        .hyper_cs_no            ( hyper_cs_n_wire       ),
        .hyper_ck_o             ( hyper_ck_wire         ),
        .hyper_ck_no            ( hyper_ck_n_wire       ),
        .hyper_rwds_o           ( hyper_rwds_o          ),
        .hyper_rwds_i           ( hyper_rwds_i          ),
        .hyper_rwds_oe_o        ( hyper_rwds_oe         ),
        .hyper_dq_i             ( hyper_dq_i            ),
        .hyper_dq_o             ( hyper_dq_o            ),
        .hyper_dq_oe_o          ( hyper_dq_oe           ),
        .hyper_reset_no         ( hyper_reset_n_wire    )
    );

   for (genvar i = 0 ; i<NumPhys; i++) begin: pad_gen

    pad_functional_pu padinst_hyper_csno0  (.OEN( 1'b0            ), .I( hyper_cs_n_wire[i][0] ), .O(                  ), .PAD( pad_hyper_csn[i][0] ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_csno1  (.OEN( 1'b0            ), .I( hyper_cs_n_wire[i][1] ), .O(                  ), .PAD( pad_hyper_csn[i][1] ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_ck     (.OEN( 1'b0            ), .I( hyper_ck_wire[i]      ), .O(                  ), .PAD( pad_hyper_ck[i]     ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_ckno   (.OEN( 1'b0            ), .I( hyper_ck_n_wire[i]    ), .O(                  ), .PAD( pad_hyper_ckn[i]    ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_rwds0  (.OEN(~hyper_rwds_oe[i]), .I( hyper_rwds_o[i]       ), .O( hyper_rwds_i[i]  ), .PAD( pad_hyper_rwds[i]   ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_resetn (.OEN( 1'b0            ), .I( hyper_reset_n_wire[i] ), .O(                  ), .PAD( pad_hyper_reset[i]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio0  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][0]      ), .O( hyper_dq_i[i][0] ), .PAD( pad_hyper_dq[i][0]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio1  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][1]      ), .O( hyper_dq_i[i][1] ), .PAD( pad_hyper_dq[i][1]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio2  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][2]      ), .O( hyper_dq_i[i][2] ), .PAD( pad_hyper_dq[i][2]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio3  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][3]      ), .O( hyper_dq_i[i][3] ), .PAD( pad_hyper_dq[i][3]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio4  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][4]      ), .O( hyper_dq_i[i][4] ), .PAD( pad_hyper_dq[i][4]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio5  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][5]      ), .O( hyper_dq_i[i][5] ), .PAD( pad_hyper_dq[i][5]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio6  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][6]      ), .O( hyper_dq_i[i][6] ), .PAD( pad_hyper_dq[i][6]  ), .PEN(1'b1 ) );
    pad_functional_pu padinst_hyper_dqio7  (.OEN(~hyper_dq_oe[i]  ), .I( hyper_dq_o[i][7]      ), .O( hyper_dq_i[i][7] ), .PAD( pad_hyper_dq[i][7]  ), .PEN(1'b1 ) );

   end
   
endmodule : hyperbus_with_pads
