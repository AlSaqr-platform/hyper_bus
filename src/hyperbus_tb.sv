// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
`timescale 1ps/1ps

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
    .AXI_DATA_WIDTH ( 16 ),
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
    .DW ( 16       ),
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
    //simulate pad delays
    //-------------------
    
    wire        wire_rwds;
    wire [7:0]  wire_dq_io;
    wire [1:0]  wire_cs_no;
    wire        wire_ck_o;
    wire        wire_ck_no;
    wire        wire_reset_no;

    pad_io pad_sim (
        .data_i   (hyper_rwds_o),   
        .oe_i     (hyper_rwds_oe_o),
        .data_o   (hyper_rwds_i),  
        .pad_io   (wire_rwds) 
    );

    pad_io #(8) pad_sim_data (
        .data_i   (hyper_dq_o),   
        .oe_i     (hyper_dq_oe_o),
        .data_o   (hyper_dq_i),  
        .pad_io   (wire_dq_io) 
    );

    pad_io #(4) pad_sim_others (
        .data_i   ({hyper_cs_no, hyper_ck_o, hyper_ck_no}),   
        .oe_i     (1'b1),
        .data_o   (),  
        .pad_io   ({wire_cs_no, wire_ck_o, wire_ck_no}) 
    );

    assign wire_reset_no = hyper_reset_no; //if delayed, a hold violation occures 


  s27ks0641 #(.mem_file_name("../src/s27ks0641.mem"), .TimingModel("S27KS0641DPBHI020")) hyperram_model
  (
    .DQ7      (wire_dq_io[7]),
    .DQ6      (wire_dq_io[6]),
    .DQ5      (wire_dq_io[5]),
    .DQ4      (wire_dq_io[4]),
    .DQ3      (wire_dq_io[3]),
    .DQ2      (wire_dq_io[2]),
    .DQ1      (wire_dq_io[1]),
    .DQ0      (wire_dq_io[0]),
    .RWDS     (wire_rwds),
    .CSNeg    (wire_cs_no[0]),
    .CK       (wire_ck_o),
    .CKNeg    (wire_ck_no),
    .RESETNeg (wire_reset_no)    
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

  int expectedResultAt05FFF3[8] = '{16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a};
  int expectedResulth0f03 = 16'h0f03;
  int expectedResulth0001 = 16'h0001;

  initial begin

    automatic logic [31:0] data [5000];
    automatic logic error;
    automatic axi_driver_t::ax_beat_t ax;
    automatic axi_driver_t::w_beat_t w;
    automatic axi_driver_t::b_beat_t b;
    automatic axi_driver_t::r_beat_t r;
    $sdf_annotate("../models/s27ks0641/s27ks0641.sdf", hyperram_model); 
    @(negedge rst_ni);
    cfg_drv.reset_master();
    axi_drv.reset_master();
    @(posedge rst_ni);
    #150us; //Wait for RAM to initalize

    // // Access the register interface.
    // cfg_drv.send_write('hdeadbeef, 'hfacefeed, '1, error);
    // repeat(3) @(posedge clk_i);
    // cfg_drv.send_read('hdeadbeef, data, error);
    // repeat(3) @(posedge clk_i);

    // // Access the AXI interface.
    // ax = new;
    // ax.ax_addr = 'b1;
    // axi_drv.send_aw(ax);

    // w = new;
    // // w.w_last = 1; //?
    // axi_drv.send_w(w);
    // axi_drv.recv_b(b);
    // repeat(3) @(posedge clk_i);

    // axi_drv.send_ar(ax);
    // axi_drv.recv_r(r);

    // repeat(10) @(posedge clk_i);
    // done = 1;

    ax = new;
    ax.ax_addr = 'h05FFF3;
    ax.ax_len = 'd7;
    ax.ax_burst = 'b01;
    axi_drv.send_ar(ax);

    for(int i = 0; i < ax.ax_len+1; i++) begin
      axi_drv.recv_r(r);
      data[i]=r.r_data;
      if(i==4) begin
        repeat(100) @(posedge clk_i);
      end
      $display("%4h", data[i]);
      assert(data[i] == expectedResultAt05FFF3[i]) else $error("Received %4h at index %p, but expected %4h", data[i], i, expectedResultAt05FFF3[i]);
    end
    
    axi_drv.send_aw(ax);
    w = new;
    w.w_last = 0;
    w.w_data = 'h0f03;
    w.w_burst = 'b01;
    w.w_strb = 2'b11;

    for(int i = 0; i < ax.ax_len+1; i++) begin
      if(i==4) begin
        repeat(100) @(posedge clk_i);
      end
      if(i==7) begin
        w.w_last = 1;
      end
      axi_drv.send_w(w);
    end
    axi_drv.recv_b(b);
    
    axi_drv.send_ar(ax);
    for(int i = 0; i < ax.ax_len+1; i++) begin
      if(i==4) begin
        repeat(100) @(posedge clk_i);
      end
      axi_drv.recv_r(r);
      data[i]=r.r_data;
      $display("%4h", data[i]);
      assert(data[i] == expectedResulth0f03) else $error("Received %4h at index %p, but expected %4h", data[i], i, expectedResulth0f03);
    end
    //TODO: Long transactions
    //With break during write

    done = 1;
  end

endmodule

    // //Without break
    // //Write
    // axi_drv.send_aw(ax);
    // w = new;
    // w.w_last = 0;
    // w.w_data = expectedResulth0001;
    // w.w_burst = 'b01;
    // w.w_strb = 2'b11;

    // for(int i = 0; i < ax.ax_len+1; i++) begin
    //   if(i==7) begin
    //     w.w_last = 1;
    //   end
    //   axi_drv.send_w(w);
    // end
    // axi_drv.recv_b(b);

    // //Read
    // axi_drv.send_ar(ax);
    // for(int i = 0; i < ax.ax_len+1; i++) begin
    //   axi_drv.recv_r(r);
    //   data[i]=r.r_data;
    //   $display("%h", data[i]);
    //   assert(data[i] == expectedResulth0001) else $error("Received %4h at index %p, but expected %4h", data[i], i, expectedResulth0001);
    // end

    // //Short transactions
    // //Write
    // ax.ax_len = 'd0;
    // ax.ax_burst = 'b01;
    // axi_drv.send_aw(ax);
    // w.w_last = 0;
    // w.w_data = 'h1111;
    // w.w_burst = 'b01;
    // w.w_strb = 2'b11;

    // for(int i = 0; i < ax.ax_len+1; i++) begin
    //   if(i==0) begin
    //     w.w_last = 1;
    //   end
    //   axi_drv.send_w(w);
    // end
    // axi_drv.recv_b(b);

    // //Read
    // axi_drv.send_ar(ax);
    // for(int i = 0; i < ax.ax_len+1; i++) begin
    //   axi_drv.recv_r(r);
    //   data[i]=r.r_data;
    //   $display("%4h", data[i]);
    //   assert(data[i] == 'h1111) else $error("Received %4h at index %p, but expected %4h", data[i], i, 'h1111);
    // end