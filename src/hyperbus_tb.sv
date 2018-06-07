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

  localparam TCLK_SYS = 4ns;
  localparam TCLK = 4ns;
  localparam NR_CS = 2;
  localparam CS_MAX = 4us/(2*4ns)-2;

  logic             clk_sys_i = 0;
  logic             clk_phy_i = 0;
  logic             rst_ni = 1;

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
    .TA ( TCLK_SYS*0.2 ),
    .TT ( TCLK_SYS*0.8 )
  ) cfg_driver_t;

  typedef axi_test::axi_driver #(
    .AW ( 32       ),
    .DW ( 16       ),
    .IW ( 10       ),
    .UW ( 1        ),
    .TA ( TCLK_SYS*0.2 ),
    .TT ( TCLK_SYS*0.8 )
  ) axi_driver_t;

  cfg_driver_t cfg_drv = new(cfg_i);
  axi_driver_t axi_drv = new(axi_i);

  logic [NR_CS-1:0] hyper_cs_no;

  wire        wire_reset_no;
  wire [1:0]  wire_cs_no;
  wire        wire_ck_o;
  wire        wire_ck_no;
  wire        wire_rwds;
  wire [7:0]  wire_dq_io;

  logic       debug_hyper_rwds_oe_o;
  logic       debug_hyper_dq_oe_o;
  logic [3:0] debug_hyper_phy_state_o;

  // Instantiate device under test.
  hyperbus_macro_deflate  dut_i (
    .clk_phy_i       ( clk_phy_i      ),
    .clk_sys_i       ( clk_sys_i      ),
    .rst_ni          ( rst_ni         ),
    .cfg_i           ( cfg_i          ),
    .axi_i           ( axi_i          ),
    .hyper_reset_no  ( wire_reset_no  ),
    .hyper_cs_no     ( hyper_cs_no    ),
    .hyper_ck_o      ( wire_ck_o      ),
    .hyper_ck_no     ( wire_ck_no     ),
    .hyper_rwds_io   ( wire_rwds      ),
    .hyper_dq_io     ( wire_dq_io     ),
    .debug_hyper_rwds_oe_o    ( debug_hyper_rwds_oe_o   ),
    .debug_hyper_dq_oe_o      ( debug_hyper_dq_oe_o     ),
    .debug_hyper_phy_state_o  ( debug_hyper_phy_state_o )
  );
    //simulate pad delays
    //-------------------
    pad_io #(2) pad_sim_cs (
        .data_i   (hyper_cs_no),   
        .oe_i     (1'b1),
        .data_o   (),  
        .pad_io   (wire_cs_no) 
    );

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
    #200ns
    rst_ni = 1;
    #TCLK;
    while (!done) begin
      clk_phy_i = 1;
      #(TCLK/2);
      clk_phy_i = 0;
      #(TCLK/2);
    end
  end

    initial begin
    repeat(3) #TCLK;
    rst_ni = 0;
    #200ns
    rst_ni = 1;
    #TCLK;
    while (!done) begin
      clk_sys_i = 1;
      #(TCLK_SYS/2);
      clk_sys_i = 0;
      #(TCLK_SYS/2);
    end
  end

  int expectedResultAt05FFF3[16] = '{16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h1001, 16'h2002, 16'h3003};
  int expectedResulth0f03 = 16'h0f03;
  int expectedResulth0001 = 16'h0001;
  int expectedResultRegWrite = 16'h8f1f;
  int expectedResultStrobe[16] = '{16'hffff, 16'hff56, 16'h34ff, 16'h3456, 16'hffff, 16'hff56, 16'h34ff, 16'h3456,16'hffff, 16'hff56, 16'h34ff, 16'h3456,16'hffff, 16'hff56, 16'h34ff, 16'h3456};
  int SomeData[16] = '{'hcafe, 'haffe, 'h0770, 'h9001, 'hface, 'hfeed, 'h0000, 'h0e0e, 'hcafe, 'haffe, 'h0000, 'h0302, 'hface, 'hfeed, 'h7000, 'h0f0f};

  initial begin

    automatic logic [15:0] reg_data;
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
    $display("Set CS_MAX to ",CS_MAX);
    cfg_drv.send_write('h08, CS_MAX, '1, error);
    //repeat(3) @(posedge clk_i);
    // cfg_drv.send_read('hdeadbeef, data, error);
    // repeat(3) @(posedge clk_i);


    //Bc of CS 0 ax.ax_addr from 0 to 3FFFFF
    ax = new;
    w = new;
    r = new;
    b = new;
    RegisterNoAddLatency(ax,w,b,r,'h8f1f);
    WordWithStrobe(ax,w,b,r);
  
    ax.ax_addr = 'h00;
    LongWriteAndRead(ax, w, b, r);
    ax.ax_addr = 'h10;
    LongWriteAndRead(ax, w, b, r);

    WriteAndReadWithStrobe(ax,w,b,r);
    AddrOutOfRange(ax, w, b, r);
    WriteAndReadWithBreak(ax, w, b, r);
    ShortWriteAndRead(ax, w, b, r);
    // Thomas(ax, w, b, r);

    #100ns;
    done = 1;
    $finish;
  end

  task Thomas (axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    //axi requests kerbin soc -> hyperbus

    ax.ax_id    = 10'h010;
    ax.ax_addr  = 32'h0000_0000;
    ax.ax_size  = 3'h1;
    ax.ax_burst = axi_pkg::BURST_INCR;
    ax.ax_len   = 8'h07;
    axi_drv.send_ar(ax);            //adapt me


    repeat (8) begin
        r.r_id      = 10'h010;
        axi_drv.recv_r(r);
        $display("Read %d - %4h", $time, r.r_data);
    end


    ax.ax_id    = 10'h010;
    ax.ax_addr  = 32'h0000_0000;
    ax.ax_size  = 3'h1;
    ax.ax_burst = axi_pkg::BURST_INCR;
    ax.ax_len   = 8'h03;
    axi_drv.send_aw(ax);         

    w.w_data    = 16'h000f;
    w.w_strb    = '1;
    w.w_last    = '0;
    $display("Write %d - %4h", $time, w.w_data);
    axi_drv.send_w(w);

    w.w_data    = 16'hbeef;
    w.w_strb    = '1;
    w.w_last    = '0;
    $display("Write %d - %4h", $time, w.w_data);
    axi_drv.send_w(w);

    w.w_data    = 16'hcafe;
    w.w_strb    = '1;
    w.w_last    = '0;
    $display("Write %d - %4h", $time, w.w_data);
    axi_drv.send_w(w);

    w.w_data    = 16'hface;
    w.w_strb    = '1;
    w.w_last    = '1;
    $display("Write %d - %4h", $time, w.w_data);
    axi_drv.send_w(w);

    axi_drv.recv_b(b);


    ax.ax_id    = 10'h010;
    ax.ax_addr  = 32'h0000_0000;
    ax.ax_size  = 3'h1;
    ax.ax_burst = axi_pkg::BURST_INCR;
    ax.ax_len   = 8'h07;
    axi_drv.send_ar(ax);       


    repeat (8) begin
        r.r_id      = 10'h010;
        axi_drv.recv_r(r);
        $display("Read %d - %4h", $time, r.r_data);
    end
  endtask : Thomas //Thomas(ax, w, b, r);



  //Writes the last word of the memory byte by byte with strobes
  task WordWithStrobe(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    ax.ax_addr = 'h3FFFFF; //Last address for CS 1
    ax.ax_len = 'd0;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    $display("----------------------\nWriting %1d word byte by byte with strobe at Addr. %8h", ax.ax_len+1, ax.ax_addr);
    axi_drv.send_aw(ax);
    w.w_data = 'h3411;
    w.w_last = 1;
    w.w_strb = 2'b10;
    axi_drv.send_w(w);
    axi_drv.recv_b(b);

    axi_drv.send_aw(ax);
    w.w_data = 'h1156;
    w.w_last = 1;
    w.w_strb = 2'b01;
    axi_drv.send_w(w);
    axi_drv.recv_b(b);

    axi_drv.send_aw(ax);
    w.w_data = 'h1111;
    w.w_last = 1;
    w.w_strb = 2'b00;
    axi_drv.send_w(w);
    axi_drv.recv_b(b);
    
    //Read
    axi_drv.send_ar(ax);
    $display("Reading %1d word from Addr. %8h", ax.ax_len+1, ax.ax_addr);

    axi_drv.recv_r(r);
    assert(r.r_data == 'h3456) $display("Ok read same data as written"); else $error("Received %4h, but expected %4h", r.r_data, 'h3456);
    
  endtask : WordWithStrobe //WordWithStrobe(ax,w,b,r);

  task WriteAndReadWithStrobe(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    ax.ax_addr = 'h05000;
    ax.ax_len = 'd15;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    $display("----------------------\nWriting %2d words with different strobe at Addr. %8h", ax.ax_len+1, ax.ax_addr);

    axi_drv.send_aw(ax);

    w.w_data = 'h3456;
    w.w_last = 0;
    w.w_strb = 2'b11;

    for(int i = 0; i < ax.ax_len+1; i++) begin
      if(i==ax.ax_len) begin
        w.w_last = 1;
      end
        w.w_strb = i%4;
      axi_drv.send_w(w);
    end
    axi_drv.recv_b(b);
    
    //Read
    axi_drv.send_ar(ax);
    $display("Reading %2d words from Addr. %8h", ax.ax_len+1, ax.ax_addr);

    for(int i = 0; i < ax.ax_len+1; i++) begin
      axi_drv.recv_r(r);
      assert(r.r_data == expectedResultStrobe[i]) else $error("Received %4h, but expected %4h", r.r_data, expectedResultStrobe[i]);
    end
    $display("Write with strobe Finished"); 
  endtask : WriteAndReadWithStrobe //WriteAndReadWithStrobe(ax,w,b,r);


  task RegisterNoAddLatency(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r, logic [31:0] reg_data);
    ax.ax_addr = 'h80000800;
    ax.ax_len = 'd0;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    axi_drv.send_ar(ax);
    $display("----------------------\nReading %1d word from Register Addr. %8h", ax.ax_len+1, ax.ax_addr);

    axi_drv.recv_r(r);
    
    $display("%4h", r.r_data);
    assert(r.r_data == expectedResultRegWrite) $display("Ok, Additional latency is activated");
    else $error("Received %4h, but expected %4h", r.r_data, expectedResultRegWrite);
    
    axi_drv.send_aw(ax);
    $display("----------------------\nWriting %1d word at Register Addr. %8h", ax.ax_len+1, ax.ax_addr);

    w.w_data = 'h8f17;
    w.w_strb = 2'b11;
    w.w_last = 1;
    axi_drv.send_w(w);
    axi_drv.recv_b(b);
    
    ax.ax_id = 'b10011;
    axi_drv.send_ar(ax);
    axi_drv.recv_r(r);
    $display("%4h", r.r_data);
    assert(r.r_data == w.w_data) $display("Ok, Additional latency is deactivated"); else $error("Received %4h, but expected %4h", r.r_data, w.w_data);
  endtask : RegisterNoAddLatency // RegisterNoAddLatency(ax,w,b,r, reg_data);

  task WriteAndReadWithBreak(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    ax.ax_len = 'd15;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    ax.ax_addr = 'h000F0000;
    $display("----------------------\nWriting %2d words at Addr. %8h with break of %4d", ax.ax_len+1, ax.ax_addr, 5000);
    axi_drv.send_aw(ax);
    w.w_last = 0;
    w.w_strb = 2'b11;

    for(int i = 0; i < ax.ax_len+1; i++) begin
      w.w_data = i;
      if(i==ax.ax_len) begin
        w.w_last = 1;
      end
      if (i==ax.ax_len-2) begin
        $display("Break");
        repeat(5000) @(posedge clk_sys_i);
      end
      axi_drv.send_w(w);
    end
    axi_drv.recv_b(b);
    if(5000 > 650) begin 
      assert(b.b_resp == 2'b10) 
      $display("Ok, received slave error because of too long break"); 
      else $error("Received %b, not appropraite response of %2b", b.b_resp, 2'b10);
    end else begin
      assert(b.b_resp == 2'b00) $display("Ok"); else $error("Received error %2b", b.b_resp);
    end

    ax.ax_len = 'd15;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    $display("----------------------\nReading %2d words at Addr. %8h with break of %3d", ax.ax_len+1, ax.ax_addr, 5000);
    axi_drv.send_ar(ax);
    for(int i = 0; i < ax.ax_len+1; i++) begin
      axi_drv.recv_r(r);
      if (i==ax.ax_len-10) begin
        $display("Break");
        repeat(5000) @(posedge clk_sys_i);
      end
    end

    if(5000 > 650) begin 
      assert(r.r_resp == 2'b10) 
      $display("Ok, received slave error because of too long break"); 
      else $error("Received %2b, not appropraite response of %2b", r.r_resp, 2'b10);
    end else begin
      assert(r.r_resp == 2'b00) $display("Ok"); else $error("Received error %2b", r.r_resp);
    end
  endtask : WriteAndReadWithBreak //WriteAndWithBreak(ax,w, r, b);

  task LongWriteAndRead(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    //Without break
    //Write
    ax.ax_len = 'd15;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    $display("----------------------\nWriting and reading %3d words at Addr. %8h", ax.ax_len+1, ax.ax_addr);

    axi_drv.send_aw(ax);

    w.w_last = 0;
    w.w_strb = 2'b11;

    for(int i = 0; i < ax.ax_len+1; i++) begin
      w.w_data = SomeData[i%16];
      if(i==ax.ax_len) begin
        w.w_last = 1;
      end
      axi_drv.send_w(w);
    end
    axi_drv.recv_b(b);
    assert(b.b_resp == 2'b00) $display("Long write finished"); else $error("Received response %2b, but expected %2b", b.b_resp, 2'b00);
    
    //Read
    axi_drv.send_ar(ax);
    for(int i = 0; i < ax.ax_len+1; i++) begin
      axi_drv.recv_r(r);
      assert(r.r_data == SomeData[i%16]) else $error ("Received %4h, but expected %4h at %d", r.r_data, w.w_data, i);
      if (i == ax.ax_len) begin $display("Long read finished, number of data items %3d", i+1); end
    end
    assert (r.r_resp == 2'b00) $display ("Ok, read response received"); else $error("Read response %2b, but expected %2b", r.r_resp, 2'b00);
  endtask : LongWriteAndRead

  task ShortWriteAndRead(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    //Short transactions
    //Write
    ax.ax_addr = 'h0; //Last possible address for CS1 
    ax.ax_len = 'd0;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;

    $display("----------------------\nWriting and reading %1d word at Addr. %8h", ax.ax_len+1, ax.ax_addr);

    axi_drv.send_aw(ax);
    w.w_last = 0;
    w.w_strb = 2'b11;
    w.w_data = 'haffe;
    for(int i = 0; i < ax.ax_len+1; i++) begin
      if(i==ax.ax_len) begin
        w.w_last = 1;
      end
      axi_drv.send_w(w);
    end
    axi_drv.recv_b(b);
    assert(b.b_resp == 2'b00) $display("Short write finished"); else $error("Received response %2b, but expected %2b", b.b_resp, 2'b00);

    axi_drv.send_ar(ax);
    axi_drv.recv_r(r);
    //$display("Word: %4h", r.r_data);
    
    assert(r.r_data == w.w_data) $display ("OK, word was written and read"); else $error("Received %4h, but expected %4h", r.r_data, w.w_data);
  endtask : ShortWriteAndRead

  task AddrOutOfRange(axi_driver_t::ax_beat_t ax, axi_driver_t::w_beat_t w, axi_driver_t::b_beat_t b, axi_driver_t::r_beat_t r);
    //Short transactions
    //Write
    ax.ax_addr = 'h900000; //Address that is out of the range 
    $display("---------------------- \nTesting write with invalid address: %8h",ax.ax_addr);
    ax.ax_len = 'd0;
    ax.ax_burst = 'b01;
    axi_drv.send_aw(ax);
    w.w_last = 0;
    w.w_data = 'haffe;
    w.w_strb = 2'b11;

    for(int i = 0; i < ax.ax_len+1; i++) begin
      if(i==ax.ax_len) begin
        w.w_last = 1;
      end
      axi_drv.send_w(w);
    end
    axi_drv.recv_b(b);
    assert(b.b_resp == 2'b11) $display ("OK, Decode error was trasnmitted"); else $error("Received b_resp %2b but expected %2b", b.b_resp, 2'b11);

    $display("Testing read with invalid address: %8h",ax.ax_addr);
    ax.ax_len = 'd0;
    ax.ax_burst = 'b01;
    ax.ax_id = 'b1001;
    axi_drv.send_ar(ax);
    axi_drv.recv_r(r);
    assert(r.r_resp == 2'b11) $display ("OK, Decode error was trasnmitted"); else $error("Received b_resp %2b but expected %2b", r.r_resp, 2'b11);
  endtask : AddrOutOfRange
endmodule // hyperbus_tb