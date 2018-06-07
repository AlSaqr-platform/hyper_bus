module hyperbus_macro_deflate #(
    parameter BURST_WIDTH = 9,
    parameter NR_CS = 2,
    parameter AXI_AW = 32,
    parameter AXI_UW = 1,
    parameter AXI_IW = 10
)(
    input  logic                   clk_phy_i,
    input  logic                   clk_sys_i,
    input  logic                    rst_ni,         // Asynchronous reset active low

    REG_BUS.in                     cfg_i,
    AXI_BUS.in                     axi_i,

    // physical interface
    output logic                   hyper_reset_no,
    inout  wire [NR_CS-1:0]        hyper_cs_no,   //With Pad
    inout  wire                    hyper_ck_o,    //With Pad
    inout  wire                    hyper_ck_no,   //With Pad
    inout  wire                    hyper_rwds_io, //With Pad
    inout  wire [7:0]              hyper_dq_io,   //With Pad

    //debug
    output logic                   debug_hyper_rwds_oe_o,
    output logic                   debug_hyper_dq_oe_o,
    output logic [3:0]             debug_hyper_phy_state_o
);

    hyperbus_macro_inflate 
    // #(
        // .BURST_WIDTH ( BURST_WIDTH ),
        // .NR_CS       ( NR_CS       ),
        // .AXI_AW      ( AXI_AW      ),
        // .AXI_UW      ( AXI_UW      ),
        // .AXI_IW      ( AXI_IW      )
    // )
     i_inflate (
        .clk_phy_i       ( clk_phy_i       ),
        .clk_sys_i       ( clk_sys_i       ),
        .rst_ni          ( rst_ni          ),         // Asynchronous reset active low
        .test_en_ti      ( 1'b0            ),
        .scan_en_ti      ( 1'b0            ),
        .scan_in_ti      ( 1'b0            ),
        .scan_out_to     (                 ),

        .cfg_i_addr      ( cfg_i.addr      ),
        .cfg_i_write     ( cfg_i.write     ),
        .cfg_i_wdata     ( cfg_i.wdata     ),
        .cfg_i_wstrb     ( cfg_i.wstrb     ),
        .cfg_i_valid     ( cfg_i.valid     ),
        .cfg_i_rdata     ( cfg_i.rdata     ),
        .cfg_i_error     ( cfg_i.error     ),
        .cfg_i_ready     ( cfg_i.ready     ),

        .axi_i_aw_id     ( axi_i.aw_id     ),
        .axi_i_aw_addr   ( axi_i.aw_addr   ),
        .axi_i_aw_len    ( axi_i.aw_len    ),
        .axi_i_aw_size   ( axi_i.aw_size   ),
        .axi_i_aw_burst  ( axi_i.aw_burst  ),
        .axi_i_aw_lock   ( axi_i.aw_lock   ),
        .axi_i_aw_cache  ( axi_i.aw_cache  ),
        .axi_i_aw_prot   ( axi_i.aw_prot   ),
        .axi_i_aw_qos    ( axi_i.aw_qos    ),
        .axi_i_aw_region ( axi_i.aw_region ),
        .axi_i_aw_user   ( axi_i.aw_user   ),
        .axi_i_aw_valid  ( axi_i.aw_valid  ),
        .axi_i_aw_ready  ( axi_i.aw_ready  ),

        .axi_i_w_data    ( axi_i.w_data    ),
        .axi_i_w_strb    ( axi_i.w_strb    ),
        .axi_i_w_last    ( axi_i.w_last    ),
        .axi_i_w_user    ( axi_i.w_user    ),
        .axi_i_w_valid   ( axi_i.w_valid   ),
        .axi_i_w_ready   ( axi_i.w_ready   ),

        .axi_i_b_id      ( axi_i.b_id      ),
        .axi_i_b_resp    ( axi_i.b_resp    ),
        .axi_i_b_user    ( axi_i.b_user    ),
        .axi_i_b_valid   ( axi_i.b_valid   ),
        .axi_i_b_ready   ( axi_i.b_ready   ),

        .axi_i_ar_id     ( axi_i.ar_id     ),
        .axi_i_ar_addr   ( axi_i.ar_addr   ),
        .axi_i_ar_len    ( axi_i.ar_len    ),
        .axi_i_ar_size   ( axi_i.ar_size   ),
        .axi_i_ar_burst  ( axi_i.ar_burst  ),
        .axi_i_ar_lock   ( axi_i.ar_lock   ),
        .axi_i_ar_cache  ( axi_i.ar_cache  ),
        .axi_i_ar_prot   ( axi_i.ar_prot   ),
        .axi_i_ar_qos    ( axi_i.ar_qos    ),
        .axi_i_ar_region ( axi_i.ar_region ),
        .axi_i_ar_user   ( axi_i.ar_user   ),
        .axi_i_ar_valid  ( axi_i.ar_valid  ),
        .axi_i_ar_ready  ( axi_i.ar_ready  ),

        .axi_i_r_id      ( axi_i.r_id      ),
        .axi_i_r_data    ( axi_i.r_data    ),
        .axi_i_r_resp    ( axi_i.r_resp    ),
        .axi_i_r_last    ( axi_i.r_last    ),
        .axi_i_r_user    ( axi_i.r_user    ),
        .axi_i_r_valid   ( axi_i.r_valid   ),
        .axi_i_r_ready   ( axi_i.r_ready   ),

        // physical interface
        .hyper_reset_no  ( hyper_reset_no ),
        .hyper_cs_no     ( hyper_cs_no    ),
        .hyper_ck_o      ( hyper_ck_o     ),
        .hyper_ck_no     ( hyper_ck_no    ),
        .hyper_rwds_io   ( hyper_rwds_io  ),
        .hyper_dq_io     ( hyper_dq_io    ),

        .debug_hyper_rwds_oe_o   ( debug_hyper_rwds_oe_o   ),
        .debug_hyper_dq_oe_o     ( debug_hyper_dq_oe_o     ),
        .debug_hyper_phy_state_o ( debug_hyper_phy_state_o )
    );

endmodule