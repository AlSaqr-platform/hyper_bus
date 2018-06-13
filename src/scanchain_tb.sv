// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
`timescale 1ps/1ps

module scanchain_tb;

  localparam TCLK = 20ns;

  logic             clk_sys_i = 0;
  logic             rst_ni = 1;

  logic       test_en_ti = 1;
  logic       scan_en_ti = 0;
  logic       scan_in_ti = 0;
  logic       scan_out_to;

  wire        wire_reset_no;
  wire [1:0]  wire_cs_no;
  wire        wire_ck_o;
  wire        wire_ck_no;
  wire        wire_rwds;
  wire [7:0]  wire_dq_io;

  logic       debug_hyper_rwds_oe_o;
  logic       debug_hyper_dq_oe_o;
  logic [3:0] debug_hyper_phy_state_o;


  REG_BUS #(
    .ADDR_WIDTH ( 32 ),
    .DATA_WIDTH ( 32 )
  ) cfg_i(clk_sys_i);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( 32 ),
    .AXI_DATA_WIDTH ( 16 ),
    .AXI_ID_WIDTH   ( 10 ),
    .AXI_USER_WIDTH ( 1  )
  ) axi_i(clk_sys_i);

  typedef reg_test::reg_driver #(
    .AW ( 32       ),
    .DW ( 32       ),
    .TA ( TCLK*0.2 ),
    .TT ( TCLK*0.8 )
  ) cfg_driver_t;

  typedef axi_test::axi_driver #(
    .AW ( 32       ),
    .DW ( 16       ),
    .IW ( 10       ),
    .UW ( 1        ),
    .TA ( TCLK*0.2 ),
    .TT ( TCLK*0.8 )
  ) axi_driver_t;

  cfg_driver_t cfg_drv = new(cfg_i);
  axi_driver_t axi_drv = new(axi_i);


  // Instantiate device under test.
  hyperbus_macro_inflate  dut_i (
    .clk_phy_i       ( clk_sys_i      ),
    .clk_sys_i       ( clk_sys_i      ),
    .rst_ni          ( rst_ni         ),
    .test_en_ti      ( test_en_ti     ),
    .scan_en_ti      ( scan_en_ti     ),
    .scan_in_ti      ( scan_in_ti     ),
    .scan_out_to     ( scan_out_to    ),
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

    .hyper_reset_no  ( wire_reset_no  ),
    .hyper_cs_no     ( wire_cs_no     ),
    .hyper_ck_o      ( wire_ck_o      ),
    .hyper_ck_no     ( wire_ck_no     ),
    .hyper_rwds_io   ( wire_rwds      ),
    .hyper_dq_io     ( wire_dq_io     )
  );
  // TODO: Instantiate model of HyperRAM/HyperFlash.

  logic done = 0;

    initial begin
    repeat(3) #TCLK;
    rst_ni = 0;
    #200ns
    // for(int i=1; i < 10; i++) begin
    //   clk_sys_i = 1;
    //   #(TCLK/2);
    //   clk_sys_i = 0;
    //   #(TCLK/2);  
    // end
    rst_ni = 1;
    #TCLK;
    while (!done) begin
      clk_sys_i = 1;
      #(TCLK/2);
      clk_sys_i = 0;
      #(TCLK/2);
    end
  end

  int expectedResultAt05FFF3[16] = '{16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h1001, 16'h2002, 16'h3003};
  int expectedResulth0f03 = 16'h0f03;
  int expectedResulth0001 = 16'h0001;
  int expectedResultRegWrite = 16'h8f1f;
  int expectedResultStrobe[16] = '{16'hffff, 16'hff56, 16'h34ff, 16'h3456, 16'hffff, 16'hff56, 16'h34ff, 16'h3456,16'hffff, 16'hff56, 16'h34ff, 16'h3456,16'hffff, 16'hff56, 16'h34ff, 16'h3456};
  int SomeData[16] = '{'hcafe, 'haffe, 'h0770, 'h9001, 'hface, 'hfeed, 'h0000, 'h0e0e, 'hcafe, 'haffe, 'h0000, 'h0302, 'hface, 'hfeed, 'h7000, 'h0f0f};

  initial begin

    @(negedge rst_ni);
    cfg_drv.reset_master();
    axi_drv.reset_master();
    @(posedge rst_ni);


    #50ns


    @(posedge clk_sys_i)
    #(TCLK/2)
    scan_en_ti = 1;
    scan_in_ti = 1;
    #(TCLK)
    scan_in_ti = 0;
    #(2*TCLK)
    scan_in_ti = 1;
    #(2*TCLK)
    scan_in_ti = 0;

    @(posedge scan_out_to)
    $info("posedge scan_out_to");



  end
endmodule