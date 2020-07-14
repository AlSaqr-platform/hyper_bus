module hyperbus #(
    parameter int unsigned NumChips      = -1,
    parameter int unsigned AxiDataWidth  = -1,
    parameter int unsigned AxiIdWidth    = -1,
    parameter type         axi_req_t     = logic,
    parameter type         axi_rsp_t     = logic
) (
    input  logic                      clk_phy_i,
    input  logic                      clk_sys_i,
    input  logic                      rst_ni,    // async, active low
    // AXI bus
    input  axi_req_t                  axi_req_i,
    output axi_rsp_t                  axi_rsp_o,
    // reg bus
    input  reg_intf_pkg::req_a32_d32  reg_req_i,
    output reg_intf_pkg::rsp_d32      reg_rsp_o,
    // physical interface
    output logic [NumChips-1:0]       hyper_cs_no,
    output logic                      hyper_ck_o,
    output logic                      hyper_ck_no,
    output logic                      hyper_rwds_o,
    input  logic                      hyper_rwds_i,
    output logic                      hyper_rwds_oe_o,
    input  logic [7:0]                hyper_dq_i,
    output logic [7:0]                hyper_dq_o,
    output logic                      hyper_dq_oe_o,
    output logic                      hyper_reset_no,
    //debug
    output logic                      debug_hyper_rwds_oe_o,
    output logic                      debug_hyper_dq_oe_o,
    output logic [3:0]                debug_hyper_phy_state_o
);

    logic rst_phy_n;
    logic rst_sys_n;

    logic clk0;   //Clk for phy and FIFOS 
    logic clk90;

    logic clk0_gen;
    logic clk90_gen;

    hyperbus_clk_gen ddr_clk (
        .clk_i    ( clk_phy_i ),
        .rst_ni   ( rst_phy_n ),
        .clk0_o   ( clk0_gen  ),
        .clk90_o  ( clk90_gen ),
        .clk180_o ( ),
        .clk270_o ( )
    );

    // clock mux for test ena

    // register file
    hyperbus_pkg::hyperbus_cfg_t    cfg;
    logic [NumChips-1:0][1:0][31:0] chip_addr_range;

    hyperbus_cfg_regs #(
        .NumChips          ( NumChips        )
    ) i_hyperbus_cfg_regs (
        .clk_i             ( clk_sys_i           ),
        .rst_ni            ( rst_sys_n           ),
        .reg_req_i         ( reg_req_i           ),
        .reg_rsp_o         ( reg_rsp_o           ),
        .cfg_o             ( cfg                 ),
        .chip_addr_range_o ( chip_addr_range     )
    );

    // axi slave

    logic clk_i;
     addr_map_i;
    logic [15:0] rx_data_i;
    logic rx_last_i;
    logic rx_error_i;
    logic rx_valid_i;
    logic rx_ready_o;
    logic [15:0] tx_data_o;
    logic [1:0] tx_strb_o;
    logic tx_valid_o;
    logic tx_ready_i;
    logic b_valid_i;
    logic b_ready_o;
    logic b_last_i;
    logic b_error_i;
    logic trans_valid_o;
    logic trans_ready_i;
    logic [-1:0] trans_address_o;
    logic [-1:0] trans_cs_o;
    logic trans_write_o;
    axi_pkg::len_t trans_burst_o;
    logic trans_burst_type_o;
    logic trans_address_space_o;

    hyperbus_axi #(
        .AxiDataWidth  ( AxiDataWidth        ),
        .AxiAddrWidth  ( 32                  ),
        .AxiIdWidth    ( AxiIdWidth          ),
        .axi_req_t     ( axi_req_t           ),
        .axi_rsp_t     ( axi_rsp_t           ),
        .NumChipSel    ( NumChips            )
    ) i_hyperbus_axi (
        .clk_i                ( clk_sys_i            ),
        .rst_ni               ( rst_sys_n            ),

        .axi_req_i            ( axi_req_i            ),  
        .axi_rsp_o            ( axi_rsp_o            ), 

        .addr_map_i           ( addr_map             ),

        .rx_data_i            ( rx_data              ),
        .rx_last_i            ( rx_last              ),
        .rx_error_i           ( rx_error             ),
        .rx_valid_i           ( rx_valid             ),
        .rx_ready_o           ( rx_ready             ),

        .tx_data_o            ( tx_data              ),
        .tx_strb_o            ( tx_strb              ),
        .tx_valid_o           ( tx_valid             ),
        .tx_ready_i           ( tx_ready             ),

        .b_valid_i            ( b_valid              ),
        .b_ready_o            ( b_ready              ),
        .b_last_i             ( b_last               ),
        .b_error_i            ( b_error              ),

        .trans_valid_o        ( trans_valid          ),
        .trans_ready_i        ( trans_ready          ),
        .trans_address_o      ( trans_address        ),
        .trans_cs_o           ( trans_cs             ),
        .trans_write_o        ( trans_write          ),
        .trans_burst_o        ( trans_burst          ),
        .trans_burst_type_o   ( trans_burst_type     ),
        .trans_address_space_o( trans_address_space  )
    );


   hyperbus_phy #(
        .NR_CS       ( NumChips       )
        ) phy_i (
        .clk0                         ( clk0                         ),
        .clk90                        ( clk90                        ),
        .rst_ni                       ( rst_phy_n                    ),

        .clk_test                     ( clk_sys_i                    ),
        .test_en_ti                   ( test_en_ti                   ),

        .cfg                          ( cfg                          ),

        .trans_valid_i                ( phy_trans_valid              ),
        .trans_ready_o                ( phy_trans_ready              ),
        .trans_address_i              ( phy_trans.address            ),
        .trans_cs_i                   ( phy_trans.cs                 ),
        .trans_write_i                ( phy_trans.write              ),
        .trans_burst_i                ( phy_trans.burst              ),
        .trans_burst_type_i           ( phy_trans.burst_type         ),
        .trans_address_space_i        ( phy_trans.address_space      ),

        .tx_valid_i                   ( phy_tx_valid                 ),
        .tx_ready_o                   ( phy_tx_ready                 ),
        .tx_data_i                    ( phy_tx.data                  ),
        .tx_strb_i                    ( phy_tx.strb                  ),

        .rx_valid_o                   ( phy_rx_valid                 ),
        .rx_ready_i                   ( phy_rx_ready                 ),
        .rx_data_o                    ( phy_rx.data                  ),
        .rx_error_o                   ( phy_rx.error                 ),
        .rx_last_o                    ( phy_rx.last                  ),

        .b_valid_o                    ( phy_b_valid                  ),
        .b_last_o                     ( phy_b_resp.last              ),
        .b_error_o                    ( phy_b_resp.error             ),

        .hyper_cs_no                  ( hyper_cs_no                  ),
        .hyper_ck_o                   ( hyper_ck_o                   ),
        .hyper_ck_no                  ( hyper_ck_no                  ),
        .hyper_rwds_o                 ( hyper_rwds_o                 ),
        .hyper_rwds_i                 ( hyper_rwds_i                 ),
        .hyper_rwds_oe_o              ( hyper_rwds_oe_o              ),
        .hyper_dq_i                   ( hyper_dq_i                   ),
        .hyper_dq_o                   ( hyper_dq_o                   ),
        .hyper_dq_oe_o                ( hyper_dq_oe_o                ),
        .hyper_reset_no               ( hyper_reset_no               ),

        .debug_hyper_rwds_oe_o        ( debug_hyper_rwds_oe_o        ),
        .debug_hyper_dq_oe_o          ( debug_hyper_dq_oe_o          ),
        .debug_hyper_phy_state_o      ( debug_hyper_phy_state_o      )
    );



endmodule : hyperbus

