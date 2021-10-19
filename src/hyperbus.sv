// Hyperbus AXI

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <paulsc@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Contributor: Luca Valente <luca.valente@unibo.it>

module hyperbus #(
    parameter int unsigned  NumChips        = -1,
    parameter int unsigned  IsClockODelayed = -1,
    parameter int unsigned  L2_AWIDTH_NOAL  = 12,
    parameter int unsigned  TRANS_SIZE      = 16,
    parameter int unsigned  NB_CH           = 8,
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
    input  logic                        clk_phy_i_90,
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

    // Physical interace: facing HyperBus
    output logic [NumChips-1:0]    hyper0_cs_no,
    output logic                   hyper0_ck_o,
    output logic                   hyper0_ck_no,
    output logic                   hyper0_rwds_o,
    input  logic                   hyper0_rwds_i,
    output logic                   hyper0_rwds_oe_o,
    input  logic [7:0]             hyper0_dq_i,
    output logic [7:0]             hyper0_dq_o,
    output logic                   hyper0_dq_oe_o,
    output logic                   hyper0_reset_no,

    output logic [NumChips-1:0]    hyper1_cs_no,
    output logic                   hyper1_ck_o,
    output logic                   hyper1_ck_no,
    output logic                   hyper1_rwds_o,
    input  logic                   hyper1_rwds_i,
    output logic                   hyper1_rwds_oe_o,
    input  logic [7:0]             hyper1_dq_i,
    output logic [7:0]             hyper1_dq_o,
    output logic                   hyper1_dq_oe_o,
    output logic                   hyper1_reset_no

);

    // Combined transfer type for CDC
    typedef struct packed {
        hyperbus_pkg::hyper_tf_t    trans;
        logic [NumChips-1:0]        cs;
    } tf_cdc_t;

    // Register file
    hyperbus_pkg::hyper_cfg_t   cfg;
    axi_rule_t [NumChips-1:0]   chip_rules;
    logic                       trans_active;

    // AXI slave
    hyperbus_pkg::hyper_rx_t    axi_rx;
    logic                       axi_rx_valid;
    logic                       axi_rx_ready;
    hyperbus_pkg::hyper_tx_t    axi_tx;
    logic                       axi_tx_valid;
    logic                       axi_tx_ready;
    logic                       axi_b_error;
    logic                       axi_b_valid;
    logic                       axi_b_ready;
    tf_cdc_t                    axi_tf_cdc;
    logic                       axi_trans_valid;
    logic                       axi_trans_ready;

    // PHY
    hyperbus_pkg::hyper_rx_t    axi_phy_rx;
    logic                       axi_phy_rx_valid;
    logic                       axi_phy_rx_ready;
    hyperbus_pkg::hyper_tx_t    axi_phy_tx;
    logic                       axi_phy_tx_valid;
    logic                       axi_phy_tx_ready;
    logic                       axi_phy_b_error;
    logic                       axi_phy_b_valid;
    logic                       axi_phy_b_ready;
    tf_cdc_t                    axi_phy_tf_cdc;
    logic                       axi_phy_trans_valid;
    logic                       axi_phy_trans_ready;
   
    // PHY
    hyperbus_pkg::hyper_rx_t    phy_rx;
    logic                       phy_rx_valid;
    logic                       phy_rx_ready;
    hyperbus_pkg::hyper_tx_t    phy_tx;
    logic                       phy_tx_valid;
    logic                       phy_tx_ready;
    logic                       phy_b_error;
    logic                       phy_b_valid;
    logic                       phy_b_ready;
    tf_cdc_t                    phy_tf_cdc;
    logic                       phy_trans_valid;
    logic                       phy_trans_ready;

    // Config register File
    hyperbus_cfg_regs #(
        .NumChips       ( NumChips      ),
        .RegAddrWidth   ( RegAddrWidth  ),
        .RegDataWidth   ( RegDataWidth  ),
        .reg_req_t      ( reg_req_t     ),
        .reg_rsp_t      ( reg_rsp_t     ),
        .rule_t         ( axi_rule_t    ),
        .RstChipBase    ( RstChipBase   ),
        .RstChipSpace   ( RstChipSpace  )
    ) i_cfg_regs (
        .clk_i          ( clk_sys_i     ),
        .rst_ni         ( rst_sys_ni    ),
        .reg_req_i      ( reg_req_i     ),
        .reg_rsp_o      ( reg_rsp_o     ),
        .cfg_o          ( cfg           ),
        .chip_rules_o   ( chip_rules    ),
        .trans_active_i ( trans_active  )
    );

    // AXI slave interfacing PHY
    hyperbus_axi #(
        .AxiDataWidth   ( AxiDataWidth      ),
        .AxiAddrWidth   ( AxiAddrWidth      ),
        .AxiIdWidth     ( AxiIdWidth        ),
        .axi_req_t      ( axi_req_t         ),
        .axi_rsp_t      ( axi_rsp_t         ),
        .axi_w_chan_t   ( axi_w_chan_t      ),
        .NumChips       ( NumChips          ),
        .rule_t         ( axi_rule_t        )
    ) i_axi_slave (
        .clk_i          ( clk_sys_i         ),
        .rst_ni         ( rst_sys_ni        ),

        .axi_req_i      ( axi_req_i         ),
        .axi_rsp_o      ( axi_rsp_o         ),

        .rx_i           ( axi_rx            ),
        .rx_valid_i     ( axi_rx_valid      ),
        .rx_ready_o     ( axi_rx_ready      ),
        .tx_o           ( axi_tx            ),
        .tx_valid_o     ( axi_tx_valid      ),
        .tx_ready_i     ( axi_tx_ready      ),
        .b_error_i      ( axi_b_error       ),
        .b_valid_i      ( axi_b_valid       ),
        .b_ready_o      ( axi_b_ready       ),
        .trans_o        ( axi_tf_cdc.trans  ),
        .trans_cs_o     ( axi_tf_cdc.cs     ),
        .trans_valid_o  ( axi_trans_valid   ),
        .trans_ready_i  ( axi_trans_ready   ),

        .chip_rules_i       ( chip_rules            ),
        .addr_mask_msb_i    ( cfg.address_mask_msb  ),
        .addr_space_i       ( cfg.address_space     ),
        .trans_active_o     ( trans_active          )
    );

    hyperbus_phy #(
        .IsClockODelayed( IsClockODelayed   ),
        .NumChips       ( NumChips          ),
        .StartupCycles  ( PhyStartupCycles  )
    ) i_phy (
        .clk_i          ( clk_phy_i         ),
        .clk_i_90       ( clk_phy_i_90      ),
        .rst_ni         ( rst_phy_ni        ),
        .test_mode_i    ( test_mode_i       ),

        .cfg_i          ( cfg               ),

        .rx_o           ( phy_rx            ),
        .rx_valid_o     ( phy_rx_valid      ),
        .rx_ready_i     ( phy_rx_ready      ),
        .tx_i           ( phy_tx            ),
        .tx_valid_i     ( phy_tx_valid      ),
        .tx_ready_o     ( phy_tx_ready      ),
        .b_error_o      ( phy_b_error       ),
        .b_valid_o      ( phy_b_valid       ),
        .b_ready_i      ( phy_b_ready       ),
        .trans_i        ( phy_tf_cdc.trans  ),
        .trans_cs_i     ( phy_tf_cdc.cs     ),
        .trans_valid_i  ( phy_trans_valid   ),
        .trans_ready_o  ( phy_trans_ready   ),

        .hyper0_cs_no,
        .hyper0_ck_o,
        .hyper0_ck_no,
        .hyper0_rwds_o,
        .hyper0_rwds_i,
        .hyper0_rwds_oe_o,
        .hyper0_dq_i,
        .hyper0_dq_o,
        .hyper0_dq_oe_o,
        .hyper0_reset_no,
        .hyper1_cs_no,
        .hyper1_ck_o,
        .hyper1_ck_no,
        .hyper1_rwds_o,
        .hyper1_rwds_i,
        .hyper1_rwds_oe_o,
        .hyper1_dq_i,
        .hyper1_dq_o,
        .hyper1_dq_oe_o,
        .hyper1_reset_no
    );

    cdc_2phase #(
        .T  ( tf_cdc_t  )
    ) i_cdc_2phase_trans (
        .src_rst_ni     ( rst_sys_ni        ),
        .src_clk_i      ( clk_sys_i         ),
        .src_data_i     ( axi_tf_cdc        ),
        .src_valid_i    ( axi_trans_valid   ),
        .src_ready_o    ( axi_trans_ready   ),

        .dst_rst_ni     ( rst_phy_ni        ),
        .dst_clk_i      ( clk_phy_i         ),
        .dst_data_o     ( axi_phy_tf_cdc        ),
        .dst_valid_o    ( axi_phy_trans_valid   ),
        .dst_ready_i    ( axi_phy_trans_ready   )
    );

    cdc_2phase #(
        .T  ( logic )
    ) i_cdc_2phase_b (
        .src_rst_ni     ( rst_phy_ni    ),
        .src_clk_i      ( clk_phy_i     ),
        .src_data_i     ( axi_phy_b_error   ),
        .src_valid_i    ( axi_phy_b_valid   ),
        .src_ready_o    ( axi_phy_b_ready   ),

        .dst_rst_ni     ( rst_sys_ni    ),
        .dst_clk_i      ( clk_sys_i     ),
        .dst_data_o     ( axi_b_error   ),
        .dst_valid_o    ( axi_b_valid   ),
        .dst_ready_i    ( axi_b_ready   )
    );

    // Write data, TX CDC FIFO
    cdc_fifo_gray  #(
        .T          ( hyperbus_pkg::hyper_tx_t  ),
        .LOG_DEPTH  ( TxFifoLogDepth            )
    ) i_cdc_fifo_tx (
        .src_rst_ni     ( rst_sys_ni    ),
        .src_clk_i      ( clk_sys_i     ),
        .src_data_i     ( axi_tx        ),
        .src_valid_i    ( axi_tx_valid  ),
        .src_ready_o    ( axi_tx_ready  ),

        .dst_rst_ni     ( rst_phy_ni    ),
        .dst_clk_i      ( clk_phy_i     ),
        .dst_data_o     ( axi_phy_tx       ),
        .dst_valid_o    ( axi_phy_tx_valid ),
        .dst_ready_i    ( axi_phy_tx_ready )
    );

    // Read data, RX CDC FIFO
    cdc_fifo_gray  #(
        .T          ( hyperbus_pkg::hyper_rx_t  ),
        .LOG_DEPTH  ( RxFifoLogDepth            )
    ) i_cdc_fifo_rx (
        .src_rst_ni     ( rst_phy_ni    ),
        .src_clk_i      ( clk_phy_i     ),
        .src_data_i     ( axi_phy_rx       ),
        .src_valid_i    ( axi_phy_rx_valid ),
        .src_ready_o    ( axi_phy_rx_ready ),

        .dst_rst_ni     ( rst_sys_ni    ),
        .dst_clk_i      ( clk_sys_i     ),
        .dst_data_o     ( axi_rx        ),
        .dst_valid_o    ( axi_rx_valid  ),
        .dst_ready_i    ( axi_rx_ready  )
    );


    logic                   s_sel; 
   
    // PHY
    hyperbus_pkg::hyper_rx_t    udma_phy_rx;
    logic                       udma_phy_rx_valid;
    logic                       udma_phy_rx_ready;
    hyperbus_pkg::hyper_tx_t    udma_phy_tx;
    logic                       udma_phy_tx_valid;
    logic                       udma_phy_tx_ready;
    tf_cdc_t                    udma_phy_tf_cdc;
    logic                       udma_phy_trans_valid;
    logic                       udma_phy_trans_ready;
   
  udma_hyperbus #(
    .L2_AWIDTH_NOAL  (L2_AWIDTH_NOAL),
    .TRANS_SIZE      (TRANS_SIZE),
    .DELAY_BIT_WIDTH (4),
    .NumChips        (NumChips), 
    .NB_CH           (NB_CH)
   ) udma_hyper (    
        .sys_clk_i               ( clk_sys_i                    ),
        .clk_phy_i               ( clk_phy_i                    ),
        .clk_phy_i_90            ( clk_phy_i_90                 ),
        .rst_ni                  ( rst_sys_ni                   ),
        .phy_rst_ni              ( rst_phy_ni                   ),

        .cfg_data_i              ( cfg_data_i                   ),
        .cfg_addr_i              ( cfg_addr_i                   ),
        .cfg_valid_i             ( cfg_valid_i                  ),
        .cfg_rwn_i               ( cfg_rwn_i                    ),
        .cfg_ready_o             ( cfg_ready_o                  ),
        .cfg_data_o              ( cfg_data_o                   ),

        .data_tx_req_o           ( data_tx_req_o                ),
        .data_tx_gnt_i           ( data_tx_gnt_i                ),
        .data_tx_valid_i         ( data_tx_valid_i              ),
        .data_tx_i               ( data_tx_i                    ),
        .data_tx_ready_o         ( data_tx_ready_o              ),
     
        .rx_data_udma_o          ( data_rx_o                    ),
        .rx_valid_udma_o         ( data_rx_valid_o              ),
        .rx_ready_udma_i         ( data_rx_ready_i              ),

        .udma_rx_startaddr_o     ( cfg_rx_startaddr_o           ),
        .udma_rx_size_o          ( cfg_rx_size_o                ),
        .cfg_rx_datasize_o       ( data_rx_datasize_o           ),
        .cfg_rx_continuous_o     ( cfg_rx_continuous_o          ),
        .udma_rx_en_o            ( cfg_rx_en_o                  ),
        .cfg_rx_clr_o            ( cfg_rx_clr_o                 ),
        .cfg_rx_en_i             ( cfg_rx_en_i                  ),
        .cfg_rx_pending_i        ( cfg_rx_pending_i             ),
        .cfg_rx_curr_addr_i      ( cfg_rx_curr_addr_i           ),
        .cfg_rx_bytes_left_i     ( cfg_rx_bytes_left_i          ),

        .udma_tx_startaddr_o     ( cfg_tx_startaddr_o           ),
        .udma_tx_size_o          ( cfg_tx_size_o                ),
        .cfg_tx_datasize_o       ( data_tx_datasize_o           ),
        .cfg_tx_continuous_o     ( cfg_tx_continuous_o          ),
        .udma_tx_en_o            ( cfg_tx_en_o                  ),
        .cfg_tx_clr_o            ( cfg_tx_clr_o                 ),
        .cfg_tx_en_i             ( cfg_tx_en_i                  ),
        .cfg_tx_pending_i        ( cfg_tx_pending_i             ),
        .cfg_tx_curr_addr_i      ( cfg_tx_curr_addr_i           ),
        .cfg_tx_bytes_left_i     ( cfg_tx_bytes_left_i          ),
        .evt_eot_hyper_o         ( evt_eot_hyper_o              ),
        // phy interface
        // we keep configuring the phy with the config regs
        .config_t_latency_access(),
        .config_en_latency_additional(),
        .config_t_cs_max(),
        .config_t_read_write_recovery(),
        .config_t_variable_latency_check(),
        .config_t_rwds_delay_line(),
        
        .trans_valid_o(udma_phy_trans_valid),
        .trans_ready_i(udma_phy_trans_ready),
        .udma_phy_tf(udma_phy_tf_cdc.trans),
        .trans_cs_o(udma_phy_tf_cdc.cs),        // chipselect      
        
        .tx_valid_o(udma_phy_tx_valid),
        .tx_ready_i(udma_phy_tx_ready),
        .udma_phy_tx(udma_phy_tx),
    
        .rx_valid_i(udma_phy_rx_valid),
        .rx_ready_o(udma_phy_rx_ready),
        .udma_phy_rx(udma_phy_rx),
            
        .mem_sel_o(),
        .busy_o()
        );


 hyperbus_arbiter i_hyperbus_arbiter
   (
   .clk_i          ( clk_phy_i         ),
   .rst_ni         ( rst_phy_ni        ),
   .udma_phy_trans_valid(udma_phy_trans_valid),
   .udma_phy_trans_ready(udma_phy_trans_ready),
   .axi_phy_trans_valid(axi_phy_trans_valid),
   .axi_phy_trans_ready(axi_phy_trans_ready),
   .phy_rx_valid(phy_rx_valid),
   .phy_rx_ready(phy_rx_ready),
   .phy_rx_last(phy_rx.last),
   .phy_tx_valid(phy_tx_valid),
   .phy_tx_ready(phy_tx_ready),
   .phy_tx_last(phy_tx.last),   
   .sel_o(s_sel)
   );   

 stream_mux #(
  .DATA_T(hyperbus_pkg::hyper_tx_t),
  .N_INP(2)
 )tx_mux(
  .inp_data_i({udma_phy_tx,axi_phy_tx}),
  .inp_valid_i({udma_phy_tx_valid,axi_phy_tx_valid}),
  .inp_ready_o({udma_phy_tx_ready,axi_phy_tx_ready}),

  .inp_sel_i(s_sel),

  .oup_data_o(phy_tx),
  .oup_valid_o(phy_tx_valid),
  .oup_ready_i(phy_tx_ready)
  );

 stream_mux #(
  .DATA_T(tf_cdc_t),
  .N_INP(2)
 )trans_mux(
  .inp_data_i({udma_phy_tf_cdc,axi_phy_tf_cdc}),
  .inp_valid_i({udma_phy_trans_valid,axi_phy_trans_valid}),
  .inp_ready_o({udma_phy_trans_ready,axi_phy_trans_ready}),

  .inp_sel_i(s_sel),

  .oup_data_o(phy_tf_cdc),
  .oup_valid_o(phy_trans_valid),
  .oup_ready_i(phy_trans_ready)
  );

 stream_demux #(
  .N_OUP(2)
 )rx_demux(
  .inp_valid_i(phy_rx_valid),
  .inp_ready_o(phy_rx_ready),

  .oup_sel_i(s_sel),

  .oup_valid_o({udma_phy_rx_valid,axi_phy_rx_valid}),
  .oup_ready_i({udma_phy_rx_ready,axi_phy_rx_ready})
  );
   
   assign udma_phy_rx = phy_rx;
   assign axi_phy_rx = phy_rx;
 

   assign axi_phy_b_error = s_sel ? '0 : phy_b_error;
   assign axi_phy_b_valid = s_sel ? '0 : phy_b_valid;
   assign phy_b_ready     = s_sel ? 1'b1 : axi_phy_b_ready;
 
   
endmodule : hyperbus
