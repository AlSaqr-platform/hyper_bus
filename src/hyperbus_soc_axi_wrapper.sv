//-------------------------------------------------------------------------------
//-- Title      : DRAM Wrapper
//-- Project    : Scarabaeus SOC
//-------------------------------------------------------------------------------
//-- File       : hyperbus_soc_axi_wrapper.sv
//-- Author     : Gian Marti      <gimarti.student.ethz.ch>
//-- Author     : Thomas Kramer   <tkramer.student.ethz.ch>
//-- Author     : Thomas E. Benz  <tbenz.student.ethz.ch>
//-- Company    : Integrated Systems Laboratory, ETH Zurich
//-- Created    : 2018-06-13
//-- Last update: 2018-06-13
//-- Platform   : ModelSim (simulation), Synopsys (synthesis)
//-- Standard   : SystemVerilog IEEE 1800-2012
//-------------------------------------------------------------------------------
//-- Description: Hyperbus Wrapper
//-------------------------------------------------------------------------------
//-- Copyright (c) 2018 Integrated Systems Laboratory, ETH Zurich
//-------------------------------------------------------------------------------
//-- Revisions  :
//-- Date        Version  Author  Description
//-- 2018-06-13  1.0      tbenz   Header Created
//-------------------------------------------------------------------------------

module hyperbus_soc_axi_wrapper(

    input  logic                   sys_clk_i,
    input  logic                   hyp_clk_i,  
    input  logic                   rst_ni,   
    input  logic                   test_en_i,   

    AXI_BUS.in                     hyper_cfg_i,
    AXI_BUS.in                     hyper_axi_i,

    // physical interface
    output logic                   hyper_reset_no,
    inout  wire [1:0]              hyper_cs_no,
    inout  wire                    hyper_ck_o,    //With Pad
    inout  wire                    hyper_ck_no,   //With Pad
    inout  wire                    hyper_rwds_io, //With Pads
    inout  wire [7:0]              hyper_dq_io,   //With Pad

    //debug signals
    output logic                   debug_hyper_rwds_oe_o,
    output logic                   debug_hyper_dq_oe_o

    );


    AXI_BUS  #(.AXI_ADDR_WIDTH(64), .AXI_DATA_WIDTH(16), .AXI_ID_WIDTH(10), .AXI_USER_WIDTH( 1)) narrow_axi_i             (.clk_i(sys_clk_i));
    AXI_BUS  #(.AXI_ADDR_WIDTH(32), .AXI_DATA_WIDTH(16), .AXI_ID_WIDTH(10), .AXI_USER_WIDTH( 1)) axi_narrow_narrow_i      (.clk_i(sys_clk_i));

    AXI_LITE #(.AXI_ADDR_WIDTH(64), .AXI_DATA_WIDTH(64)) cfg_hyper_axi_lite_i (.clk_i(sys_clk_i));
    REG_BUS  #(.ADDR_WIDTH    (64), .DATA_WIDTH    (64)) cfg_hyper_reg_full   (.clk_i(sys_clk_i));
    REG_BUS  #(.ADDR_WIDTH    (32), .DATA_WIDTH    (32)) cfg_hyper_reg        (.clk_i(sys_clk_i));


    //map register bus down to address 0 and translate 64bit to 32bit
    assign cfg_hyper_reg.addr                = ((cfg_hyper_reg_full.addr [31:0]) - 32'h3000_1000) >> 1;
    assign cfg_hyper_reg.write               =   cfg_hyper_reg_full.write;
    assign cfg_hyper_reg.wdata               =   cfg_hyper_reg_full.wdata[31:0];
    assign cfg_hyper_reg.wstrb               =   cfg_hyper_reg_full.wstrb;
    assign cfg_hyper_reg.valid               =   cfg_hyper_reg_full.valid;
 
    assign cfg_hyper_reg_full.ready          =   cfg_hyper_reg.ready;
    assign cfg_hyper_reg_full.error          =   cfg_hyper_reg.error;
    assign cfg_hyper_reg_full.rdata[63:32]   =   32'h0; //32'hcafeface;
    assign cfg_hyper_reg_full.rdata[31: 0]   =   cfg_hyper_reg.rdata;



    axi_to_axi_lite #(
        .NUM_PENDING_RD         ( 1                            ), 
        .NUM_PENDING_WR         ( 1                            )
    ) hyper_axi2axilite_i (              
         
        .clk_i                  ( sys_clk_i                    ), 
        .rst_ni                 ( rst_ni                       ), 
        .in                     ( hyper_cfg_i                  ),
        .out                    ( cfg_hyper_axi_lite_i.out     )
    );         
         
    axi_lite_to_reg #(         
        .ADDR_WIDTH             ( 64                           ), 
        .DATA_WIDTH             ( 64                           ),
        .DECOUPLE_W             ( 1                            )
    ) hypper_axilite2regitf_i (           
        .clk_i                  ( sys_clk_i                    ),
        .rst_ni                 ( rst_ni                       ),
        .axi_i                  ( cfg_hyper_axi_lite_i.in      ),
        .reg_o                  ( cfg_hyper_reg_full.out       )
    );


    hyperbus_macro_deflate #(
        .NR_CS                  ( 2                            ),
        .BURST_WIDTH            ( 9                            ),
        .AXI_AW                 ( 32                           ),
        .AXI_UW                 ( 1                            ),
        .AXI_IW                 ( 10                           )
      
    ) hyperbus_soc_top_i (

        .clk_phy_i              ( hyp_clk_i                    ),
        .clk_sys_i              ( sys_clk_i                    ),
        .rst_ni                 ( rst_ni                       ),
        .test_en_ti             ( test_en_i                    ),
        .cfg_i                  ( cfg_hyper_reg.in             ),
        .axi_i                  ( axi_narrow_narrow_i.in       ),
        .hyper_reset_no         ( hyper_reset_no               ),
        .hyper_cs_no            ( hyper_cs_no                  ),
        .hyper_ck_o             ( hyper_ck_o                   ),
        .hyper_ck_no            ( hyper_ck_no                  ),
        .hyper_rwds_io          ( hyper_rwds_io                ),
        .hyper_dq_io            ( hyper_dq_io                  ),
        .debug_hyper_rwds_oe_o  ( debug_hyper_rwds_oe_o        ),
        .debug_hyper_dq_oe_o    ( debug_hyper_dq_oe_o          ),
        .debug_hyper_phy_state_o(                              )

    );


    `ifndef SYNTHESIS
        axi_prober #(.AW(64), .DW(64), .UW( 1), .IW(10)) hyper_axi_prober_i        (.clk_i(sys_clk_i), .rst_ni(rst_ni), .axi_probe_i(hyper_axi_i           ));
        axi_prober #(.AW(32), .DW(16), .UW( 1), .IW(10)) hyper_axi_prober_narrow_i (.clk_i(sys_clk_i), .rst_ni(rst_ni), .axi_probe_i(axi_narrow_narrow_i   ));
    `endif

    kerbin_axi_addr_size_converter #(
        .AW_IN                  ( 64                       ),
        .AW_OUT                 ( 32                       ),
        .DW                     ( 16                       ),
        .UW                     (  1                       ),
        .IW                     ( 10                       )

        ) axi_addr_conv_i (
        .clk_i                  ( sys_clk_i                ),
        .axi_in                 ( narrow_axi_i.in          ),
        .axi_out                ( axi_narrow_narrow_i.out  )

        );

    //le fun :)
    axi_size_conv_DOWNSIZE #(
        .AXI_ADDR_WIDTH         ( 64                       ),
        .AXI_DATA_WIDTH_IN      ( 64                       ),
        .AXI_USER_WIDTH_IN      (  1                       ),
        .AXI_ID_WIDTH_IN        ( 10                       ),
        .AXI_DATA_WIDTH_OUT     ( 16                       ),
        .AXI_USER_WIDTH_OUT     (  1                       ),
        .AXI_ID_WIDTH_OUT       ( 10                       )
                        
    ) hyper_axi_ds_i (

        .clk_i                  ( sys_clk_i                ),
        .rst_ni                 ( rst_ni                   ),

        .axi_slave_aw_valid_i   ( hyper_axi_i.aw_valid     ),
        .axi_slave_aw_addr_i    ( hyper_axi_i.aw_addr      ),
        .axi_slave_aw_prot_i    ( hyper_axi_i.aw_prot      ),
        .axi_slave_aw_region_i  ( hyper_axi_i.aw_region    ),
        .axi_slave_aw_len_i     ( hyper_axi_i.aw_len       ),
        .axi_slave_aw_burst_i   ( hyper_axi_i.aw_burst     ),
        .axi_slave_aw_size_i    ( hyper_axi_i.aw_size      ),
        .axi_slave_aw_lock_i    ( hyper_axi_i.aw_lock      ),
        .axi_slave_aw_cache_i   ( hyper_axi_i.aw_cache     ),
        .axi_slave_aw_qos_i     ( hyper_axi_i.aw_qos       ),
        .axi_slave_aw_id_i      ( hyper_axi_i.aw_id        ),
        .axi_slave_aw_user_i    ( hyper_axi_i.aw_user      ),
        .axi_slave_aw_ready_o   ( hyper_axi_i.aw_ready     ),

        .axi_slave_w_valid_i    ( hyper_axi_i.w_valid      ),
        .axi_slave_w_data_i     ( hyper_axi_i.w_data       ),
        .axi_slave_w_strb_i     ( hyper_axi_i.w_strb       ),
        .axi_slave_w_user_i     ( hyper_axi_i.w_user       ),
        .axi_slave_w_last_i     ( hyper_axi_i.w_last       ),
        .axi_slave_w_ready_o    ( hyper_axi_i.w_ready      ),

        .axi_slave_b_valid_o    ( hyper_axi_i.b_valid      ),
        .axi_slave_b_resp_o     ( hyper_axi_i.b_resp       ),
        .axi_slave_b_id_o       ( hyper_axi_i.b_id         ),
        .axi_slave_b_user_o     ( hyper_axi_i.b_user       ),
        .axi_slave_b_ready_i    ( hyper_axi_i.b_ready      ), 

        .axi_slave_ar_valid_i   ( hyper_axi_i.ar_valid     ),
        .axi_slave_ar_addr_i    ( hyper_axi_i.ar_addr      ),
        .axi_slave_ar_prot_i    ( hyper_axi_i.ar_prot      ),
        .axi_slave_ar_region_i  ( hyper_axi_i.ar_region    ),
        .axi_slave_ar_len_i     ( hyper_axi_i.ar_len       ),
        .axi_slave_ar_size_i    ( hyper_axi_i.ar_size      ),
        .axi_slave_ar_burst_i   ( hyper_axi_i.ar_burst     ),
        .axi_slave_ar_lock_i    ( hyper_axi_i.ar_lock      ),
        .axi_slave_ar_cache_i   ( hyper_axi_i.ar_cache     ),
        .axi_slave_ar_qos_i     ( hyper_axi_i.ar_qos       ),
        .axi_slave_ar_id_i      ( hyper_axi_i.ar_id        ),
        .axi_slave_ar_user_i    ( hyper_axi_i.ar_user      ),
        .axi_slave_ar_ready_o   ( hyper_axi_i.ar_ready     ), 

        .axi_slave_r_valid_o    ( hyper_axi_i.r_valid      ),
        .axi_slave_r_data_o     ( hyper_axi_i.r_data       ),
        .axi_slave_r_resp_o     ( hyper_axi_i.r_resp       ),
        .axi_slave_r_last_o     ( hyper_axi_i.r_last       ),
        .axi_slave_r_id_o       ( hyper_axi_i.r_id         ),
        .axi_slave_r_user_o     ( hyper_axi_i.r_user       ),
        .axi_slave_r_ready_i    ( hyper_axi_i.r_ready      ),

        .axi_master_aw_valid_o  ( narrow_axi_i.aw_valid    ),
        .axi_master_aw_addr_o   ( narrow_axi_i.aw_addr     ),
        .axi_master_aw_prot_o   ( narrow_axi_i.aw_prot     ),
        .axi_master_aw_region_o ( narrow_axi_i.aw_region   ),
        .axi_master_aw_len_o    ( narrow_axi_i.aw_len      ),
        .axi_master_aw_burst_o  ( narrow_axi_i.aw_burst    ),
        .axi_master_aw_size_o   ( narrow_axi_i.aw_size     ),
        .axi_master_aw_lock_o   ( narrow_axi_i.aw_lock     ),
        .axi_master_aw_cache_o  ( narrow_axi_i.aw_cache    ),
        .axi_master_aw_qos_o    ( narrow_axi_i.aw_qos      ),
        .axi_master_aw_id_o     ( narrow_axi_i.aw_id       ),
        .axi_master_aw_user_o   ( narrow_axi_i.aw_user     ),
        .axi_master_aw_ready_i  ( narrow_axi_i.aw_ready    ),

        .axi_master_w_valid_o   ( narrow_axi_i.w_valid     ),
        .axi_master_w_data_o    ( narrow_axi_i.w_data      ),
        .axi_master_w_strb_o    ( narrow_axi_i.w_strb      ),
        .axi_master_w_user_o    ( narrow_axi_i.w_user      ),
        .axi_master_w_last_o    ( narrow_axi_i.w_last      ),
        .axi_master_w_ready_i   ( narrow_axi_i.w_ready     ),

        .axi_master_b_valid_i   ( narrow_axi_i.b_valid     ),
        .axi_master_b_resp_i    ( narrow_axi_i.b_resp      ),
        .axi_master_b_id_i      ( narrow_axi_i.b_id        ),
        .axi_master_b_user_i    ( narrow_axi_i.b_user      ),
        .axi_master_b_ready_o   ( narrow_axi_i.b_ready     ),

        .axi_master_ar_valid_o  ( narrow_axi_i.ar_valid    ),
        .axi_master_ar_addr_o   ( narrow_axi_i.ar_addr     ),
        .axi_master_ar_prot_o   ( narrow_axi_i.ar_prot     ),
        .axi_master_ar_region_o ( narrow_axi_i.ar_region   ),
        .axi_master_ar_len_o    ( narrow_axi_i.ar_len      ),
        .axi_master_ar_size_o   ( narrow_axi_i.ar_size     ),
        .axi_master_ar_burst_o  ( narrow_axi_i.ar_burst    ),
        .axi_master_ar_lock_o   ( narrow_axi_i.ar_lock     ),
        .axi_master_ar_cache_o  ( narrow_axi_i.ar_cache    ),
        .axi_master_ar_qos_o    ( narrow_axi_i.ar_qos      ),
        .axi_master_ar_id_o     ( narrow_axi_i.ar_id       ),
        .axi_master_ar_user_o   ( narrow_axi_i.ar_user     ),
        .axi_master_ar_ready_i  ( narrow_axi_i.ar_ready    ),

        .axi_master_r_valid_i   ( narrow_axi_i.r_valid     ),
        .axi_master_r_data_i    ( narrow_axi_i.r_data      ),
        .axi_master_r_resp_i    ( narrow_axi_i.r_resp      ),
        .axi_master_r_last_i    ( narrow_axi_i.r_last      ),
        .axi_master_r_id_i      ( narrow_axi_i.r_id        ),
        .axi_master_r_user_i    ( narrow_axi_i.r_user      ),
        .axi_master_r_ready_o   ( narrow_axi_i.r_ready     )

    );

endmodule //hyperbus_soc_axi_wrapper