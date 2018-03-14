// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

`timescale 1ps/1ps

module hyperbus_phy_tb;

  localparam TCLK = 3ns;
  localparam NR_CS = 2;
  localparam BURST_WIDTH = 12;

  logic                   clk_i;
  logic                   rst_ni;
  logic                   trans_valid_i = 0;
  logic                   trans_ready_o;
  logic [31:0]            trans_address_i = 0;
  logic [NR_CS-1:0]       trans_cs_i = 0;
  logic                   trans_write_i = 0;
  logic [BURST_WIDTH-1:0] trans_burst_i = 0;
  logic                   tx_valid_i;
  logic                   tx_ready_o;
  logic [15:0]            tx_data_i;
  logic [1:0]             tx_strb_i;
  logic                   rx_valid_o;
  logic                   rx_ready_i = 0;
  logic [15:0]            rx_data_o;
  logic [NR_CS-1:0]       hyper_cs_no;
  logic                   hyper_ck_o;
  logic                   hyper_ck_no;
  logic                   hyper_rwds_o;
  logic                   hyper_rwds_i;
  logic                   hyper_rwds_oe_o;
  logic [7:0]             hyper_dq_i;
  logic [7:0]             hyper_dq_o;
  logic                   hyper_dq_oe_o;
  logic                   hyper_reset_no;

  // Instantiate device under test.
  hyperbus_phy #(
    .NR_CS(NR_CS),
    .BURST_WIDTH(BURST_WIDTH)
  ) dut_i (
    .clk_i                ( clk_i           ),
    .rst_ni               ( rst_ni          ),
    .trans_valid_i        ( trans_valid_i   ),
    .trans_ready_o        ( trans_ready_o   ),
    .trans_address_i      ( trans_address_i ),
    .trans_cs_i           ( trans_cs_i      ),
    .trans_write_i        ( trans_write_i   ),
    .trans_burst_i        ( trans_burst_i   ),
    .tx_valid_i           ( tx_valid_i      ),
    .tx_ready_o           ( tx_ready_o      ),
    .tx_data_i            ( tx_data_i       ),
    .tx_strb_i            ( tx_strb_i       ),
    .rx_valid_o           ( rx_valid_o      ),
    .rx_ready_i           ( rx_ready_i      ),
    .rx_data_o            ( rx_data_o       ),
    .hyper_cs_no          ( hyper_cs_no     ),
    .hyper_ck_o           ( hyper_ck_o      ),
    .hyper_ck_no          ( hyper_ck_no     ),
    .hyper_rwds_o         ( hyper_rwds_o    ),
    .hyper_rwds_i         ( hyper_rwds_i    ),
    .hyper_rwds_oe_o      ( hyper_rwds_oe_o ),
    .hyper_dq_i           ( hyper_dq_i      ),
    .hyper_dq_o           ( hyper_dq_o      ),
    .hyper_dq_oe_o        ( hyper_dq_oe_o   ),
    .hyper_reset_no       ( hyper_reset_no  )
  );

  wire        rwds;
  wire [7:0 ] dq_io;

  // TODO: Instantiate model of HyperRAM/HyperFlash.
  pad_simulation pad_sim (
    .data_i   (hyper_rwds_o),   
    .oe_i     (hyper_rwds_oe_o),
    .data_o   (hyper_rwds_i),  
    .pad_io   (rwds) 
  );

  assign hyper_dq_i = dq_io;
  assign dq_io = hyper_dq_oe_o ? hyper_dq_o : 8'bz;

  s27ks0641 #(.mem_file_name("../src/s27ks0641.mem"), .TimingModel("S27KS0641DPBHI020")) hyperram_model
  (
    .DQ7      (dq_io[7]),
    .DQ6      (dq_io[6]),
    .DQ5      (dq_io[5]),
    .DQ4      (dq_io[4]),
    .DQ3      (dq_io[3]),
    .DQ2      (dq_io[2]),
    .DQ1      (dq_io[1]),
    .DQ0      (dq_io[0]),
    .RWDS     (rwds),
    .CSNeg    (hyper_cs_no[0]),
    .CK       (hyper_ck_o),
    .CKNeg    (hyper_ck_no),
    .RESETNeg (hyper_reset_no)    
  );

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

  logic start = 1'b0;

  initial begin
    $sdf_annotate("../models/s27ks0641/s27ks0641.sdf", hyperram_model);
    #150us
    repeat(20) #TCLK;
    #1ns

    doReadTransaction(32'h05FFFC, 8);
    doWriteTransaction(32'h0, 8, 16'h1234);
    doReadTransaction(32'h0, 8);

    #50ns done = 1;

  end

  task doReadTransaction(logic[31:0] address, int burst);

    wait(~trans_valid_i);

    if(trans_ready_o) begin
      wait(~trans_ready_o);
      #TCLK;
    end

    trans_address_i = address;
    trans_burst_i = burst;
    trans_write_i = 0;
    trans_cs_i = 2'b01;

    trans_valid_i = 1;
    wait(trans_ready_o);
    #TCLK;
    trans_valid_i = 0;

    rx_ready_i = 1;
    for(int i = 0; i<burst; i++) begin
      wait(rx_valid_o);
      #(TCLK/2);
      $display("Data at address %h is %h", address+i, rx_data_o);
      #(TCLK/2*3);
    end
    wait(~rx_valid_o);
    rx_ready_i = 0;

  endtask : doReadTransaction

  task doWriteTransaction(logic [31:0] address, int burst, logic [15:0] data);
    
    wait (~trans_valid_i)

    if(trans_ready_o) begin
      wait(~trans_ready_o);
      #TCLK;
    end

    trans_address_i = address;
    trans_burst_i = burst;
    trans_write_i = 1;
    trans_cs_i = 2'b01;
    tx_data_i = data;
    tx_strb_i = 1'b0;

    trans_valid_i = 1;
    wait(trans_ready_o);
    #TCLK;
    trans_valid_i = 0;

  endtask : doWriteTransaction

endmodule
