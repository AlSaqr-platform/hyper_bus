// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

module hyperbus_tb;

  localparam TCLK = 3ns;
  localparam NR_CS = 2;

  logic             clk_i = 0;
  logic             rst_ni = 1;

  REG_BUS #(
    .ADDR_WIDTH ( 32 ),
    .DATA_WIDTH ( 32 )
  ) cfg_i(clk_i);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( 32 ),
    .AXI_DATA_WIDTH ( 32 ),
    .AXI_ID_WIDTH   ( 4  ),
    .AXI_USER_WIDTH ( 0  )
  ) axi_i(clk_i);

  typedef reg_test::reg_driver #(
    .AW ( 32       ),
    .DW ( 32       ),
    .TA ( TCLK*0.2 ),
    .TT ( TCLK*0.8 )
  ) cfg_driver_t;

  typedef axi_test::axi_driver #(
    .AW ( 32       ),
    .DW ( 32       ),
    .IW ( 4        ),
    .UW ( 0        ),
    .TA ( TCLK*0.2 ),
    .TT ( TCLK*0.8 )
  ) axi_driver_t;

  cfg_driver_t cfg_drv = new(cfg_i);
  axi_driver_t axi_drv = new(axi_i);

  logic [NR_CS-1:0] hyper_cs_no;
  logic             hyper_ck_o;
  logic             hyper_ck_no;
  logic             hyper_rwds_o;
  logic             hyper_rwds_i;
  logic             hyper_rwds_oe_o;
  logic [7:0]       hyper_dq_i;
  logic [7:0]       hyper_dq_o;
  logic             hyper_dq_oe_o;
  logic             hyper_reset_no;

  // Instantiate device under test.
  hyperbus #(
    .NR_CS(NR_CS)
  ) dut_i (
    .clk_i           ( clk_i           ),
    .rst_ni          ( rst_ni          ),
    .cfg_i           ( cfg_i           ),
    .axi_i           ( axi_i           ),
    .hyper_cs_no     ( hyper_cs_no     ),
    .hyper_ck_o      ( hyper_ck_o      ),
    .hyper_ck_no     ( hyper_ck_no     ),
    .hyper_rwds_o    ( hyper_rwds_o    ),
    .hyper_rwds_i    ( hyper_rwds_i    ),
    .hyper_rwds_oe_o ( hyper_rwds_oe_o ),
    .hyper_dq_i      ( hyper_dq_i      ),
    .hyper_dq_o      ( hyper_dq_o      ),
    .hyper_dq_oe_o   ( hyper_dq_oe_o   ),
    .hyper_reset_no  ( hyper_reset_no  )
  );

  // TODO: Instantiate model of HyperRAM/HyperFlash.

  logic done = 0;

  initial begin
    repeat(3) #TCLK;
    rst_ni = 0;
    repeat(3) #TCLK;
    rst_ni = 1;
    #TCLK;
    while (!done) begin
      clk_i = 1;
      #(TCLK/2);
      clk_i = 0;
      #(TCLK/2);
    end
  end

  initial begin
    automatic logic [31:0] data;
    automatic logic error;
    automatic axi_driver_t::ax_beat_t ax;
    automatic axi_driver_t::w_beat_t w;
    automatic axi_driver_t::b_beat_t b;
    automatic axi_driver_t::r_beat_t r;

    @(negedge rst_ni);
    cfg_drv.reset_master();
    axi_drv.reset_master();
    @(posedge rst_ni);
    repeat(3) @(posedge clk_i);

    // Access the register interface.
    cfg_drv.send_write('hdeadbeef, 'hfacefeed, '1, error);
    repeat(3) @(posedge clk_i);
    cfg_drv.send_read('hdeadbeef, data, error);
    repeat(3) @(posedge clk_i);

    // Access the AXI interface.
    ax = new;
    axi_drv.send_aw(ax);
    w = new;
    w.w_last = 1;
    axi_drv.send_w(w);
    axi_drv.recv_b(b);
    repeat(3) @(posedge clk_i);

    axi_drv.send_ar(ax);
    axi_drv.recv_r(r);

    repeat(10) @(posedge clk_i);
    done = 1;

  end

endmodule
