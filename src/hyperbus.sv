// Hyperbus AXI

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <paulsc@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module hyperbus #(
    parameter int unsigned  NumChips        = -1,
    parameter int unsigned  AxiAddrWidth    = -1,
    parameter int unsigned  AxiDataWidth    = -1,
    parameter int unsigned  AxiIdWidth      = -1,
    parameter type          axi_req_t       = logic,
    parameter type          axi_rsp_t       = logic,
    parameter type          reg_req_t       = logic,
    parameter type          reg_rsp_t       = logic,
    parameter type          axi_rule_t      = logic
) (
    input  logic                        clk_phy_i,
    input  logic                        clk_sys_i,
    input  logic                        rst_ni,
    input  logic                        test_mode_i,
    // AXI bus
    input  axi_req_t                    axi_req_i,
    output axi_rsp_t                    axi_rsp_o,
    // Reg bus
    input  reg_req_t                    reg_req_i,
    output reg_rsp_t                    reg_rsp_o,
    // PHY interface
    output logic [NumChips-1:0]         hyper_cs_no,
    output logic                        hyper_ck_o,
    output logic                        hyper_ck_no,
    output logic                        hyper_rwds_o,
    input  logic                        hyper_rwds_i,
    output logic                        hyper_rwds_oe_o,
    input  logic [7:0]                  hyper_dq_i,
    output logic [7:0]                  hyper_dq_o,
    output logic                        hyper_dq_oe_o,
    output logic                        hyper_reset_no
);

    // Combined transfer type for CDC
    typedef struct packed {
        hyperbus_pkg::hyper_tf_t    trans;
        logic [NumChips-1:0]        cs;
    } tf_cdc_t;

    // Clock and reset generation
    logic rst_phy_n;
    logic rst_sys_n;
    logic clk_phy;      // Clock for PHY and FIFOs

    // Register file
    hyperbus_pkg::hyper_cfg_t   cfg;
    axi_rule_t [NumChips-1:0]   chip_rules;

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


    // Create synchronized resets for PHY
    rstgen i_rstgen_phy (
        .clk_i       ( clk_phy_i    ),
        .rst_ni      ( rst_ni       ),
        .test_mode_i ( test_mode_i  ),
        .rst_no      ( rst_phy_n    ),
        .init_no     (  )
    );

    // Create synchronised reset for system interfaces
    rstgen i_rstgen_sys (
        .clk_i       ( clk_sys_i    ),
        .rst_ni      ( rst_ni       ),
        .test_mode_i ( test_mode_i  ),
        .rst_no      ( rst_sys_n    ),
        .init_no     (  )
    );

    // Use system clock for PHY in test mode
    tc_clk_mux2 i_test_mux_clk_phy (
        .clk0_i     ( clk_phy_i     ),
        .clk1_i     ( clk_sys_i     ),
        .clk_sel_i  ( test_mode_i   ),
        .clk_o      ( clk_phy       )
    );

    // Config register File
    hyperbus_cfg_regs #(
        .NumChips       ( NumChips      ),
        .reg_req_t      ( reg_req_t     ),
        .reg_rsp_t      ( reg_rsp_t     ),
        .rule_t         ( axi_rule_t    )
    ) i_cfg_regs (
        .clk_i          ( clk_sys_i     ),
        .rst_ni         ( rst_sys_n     ),
        .reg_req_i      ( reg_req_i     ),
        .reg_rsp_o      ( reg_rsp_o     ),
        .cfg_o          ( cfg           ),
        .chip_rules_o   ( chip_rules    )
    );

    // AXI slave interfacing PHY
    hyperbus_axi #(
        .AxiDataWidth   ( AxiDataWidth      ),
        .AxiAddrWidth   ( AxiAddrWidth      ),
        .AxiIdWidth     ( AxiIdWidth        ),
        .axi_req_t      ( axi_req_t         ),
        .axi_rsp_t      ( axi_rsp_t         ),
        .NumChips       ( NumChips          ),
        .rule_t         ( axi_rule_t        )
    ) i_axi_slave (
        .clk_i          ( clk_sys_i         ),
        .rst_ni         ( rst_sys_n         ),

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

        .chip_rules_i   ( chip_rules        ),
        .addr_space_i   ( cfg.address_space )
    );

    hyperbus_phy #(
        .NumChips       ( NumChips          )
    ) i_phy (
        .clk_i          ( clk_phy           ),
        .rst_ni         ( rst_phy_n         ),
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

    cdc_2phase #(
        .T  ( tf_cdc_t  )
    ) i_cdc_2phase_trans (
        .src_rst_ni     ( rst_sys_n         ),
        .src_clk_i      ( clk_sys_i         ),
        .src_data_i     ( axi_tf_cdc        ),
        .src_valid_i    ( axi_trans_valid   ),
        .src_ready_o    ( axi_trans_ready   ),

        .dst_rst_ni     ( rst_phy_n         ),
        .dst_clk_i      ( clk_phy           ),
        .dst_data_o     ( phy_tf_cdc        ),
        .dst_valid_o    ( phy_trans_valid   ),
        .dst_ready_i    ( phy_trans_ready   )
    );

    cdc_2phase #(
        .T  ( logic )
    ) i_cdc_2phase_b (
        .src_rst_ni     ( rst_phy_n     ),
        .src_clk_i      ( clk_phy       ),
        .src_data_i     ( phy_b_error   ),
        .src_valid_i    ( phy_b_valid   ),
        .src_ready_o    ( phy_b_ready   ),

        .dst_rst_ni     ( rst_sys_n     ),
        .dst_clk_i      ( clk_sys_i     ),
        .dst_data_o     ( axi_b_error   ),
        .dst_valid_o    ( axi_b_valid   ),
        .dst_ready_i    ( axi_b_ready   )
    );

    // Write data, TX CDC FIFO
    cdc_fifo_gray  #(
        .T          ( hyperbus_pkg::hyper_tx_t  ),
        .LOG_DEPTH  ( 2                         )
    ) i_cdc_fifo_tx (
        .src_rst_ni     ( rst_sys_n     ),
        .src_clk_i      ( clk_sys_i     ),
        .src_data_i     ( axi_tx        ),
        .src_valid_i    ( axi_tx_valid  ),
        .src_ready_o    ( axi_tx_ready  ),

        .dst_rst_ni     ( rst_phy_n     ),
        .dst_clk_i      ( clk_phy       ),
        .dst_data_o     ( phy_tx        ),
        .dst_valid_o    ( phy_tx_valid  ),
        .dst_ready_i    ( phy_tx_ready  )
    );

    // Read data, RX CDC FIFO
    cdc_fifo_gray  #(
        .T          ( hyperbus_pkg::hyper_rx_t  ),
        .LOG_DEPTH  ( 2                         )
    ) i_cdc_fifo_rx (
        .src_rst_ni     ( rst_phy_n     ),
        .src_clk_i      ( clk_phy       ),
        .src_data_i     ( phy_rx        ),
        .src_valid_i    ( phy_rx_valid  ),
        .src_ready_o    ( phy_rx_ready  ),

        .dst_rst_ni     ( rst_sys_n     ),
        .dst_clk_i      ( clk_sys_i     ),
        .dst_data_o     ( axi_rx        ),
        .dst_valid_o    ( axi_rx_valid  ),
        .dst_ready_i    ( axi_rx_ready  )
    );

endmodule : hyperbus
