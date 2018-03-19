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

  timeunit 1ns;

  localparam TCLK = 3ns;
  localparam NR_CS = 2;
  localparam BURST_WIDTH = 12;

  logic                   clk_i;
  logic                   rst_ni;
  logic                   trans_valid_i;
  logic                   trans_ready_o;
  logic [31:0]            trans_address_i;
  logic [NR_CS-1:0]       trans_cs_i;
  logic                   trans_write_i;
  logic [BURST_WIDTH-1:0] trans_burst_i;
  logic                   trans_address_space_i;
  logic                   tx_valid_i;
  logic                   tx_ready_o;
  logic [15:0]            tx_data_i;
  logic [1:0]             tx_strb_i;
  logic                   rx_valid_o;
  logic                   rx_ready_i;
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
    .clk_i                ( clk_i                 ),
    .rst_ni               ( rst_ni                ),
    .trans_valid_i        ( trans_valid_i         ),
    .trans_ready_o        ( trans_ready_o         ),
    .trans_address_i      ( trans_address_i       ),
    .trans_cs_i           ( trans_cs_i            ),
    .trans_write_i        ( trans_write_i         ),
    .trans_burst_i        ( trans_burst_i         ),
    .trans_address_space_i( trans_address_space_i ),
    .tx_valid_i           ( tx_valid_i            ),
    .tx_ready_o           ( tx_ready_o            ),
    .tx_data_i            ( tx_data_i             ),
    .tx_strb_i            ( tx_strb_i             ),
    .rx_valid_o           ( rx_valid_o            ),
    .rx_ready_i           ( rx_ready_i            ),
    .rx_data_o            ( rx_data_o             ),
    .hyper_cs_no          ( hyper_cs_no           ),
    .hyper_ck_o           ( hyper_ck_o            ),
    .hyper_ck_no          ( hyper_ck_no           ),
    .hyper_rwds_o         ( hyper_rwds_o          ),
    .hyper_rwds_i         ( hyper_rwds_i          ),
    .hyper_rwds_oe_o      ( hyper_rwds_oe_o       ),
    .hyper_dq_i           ( hyper_dq_i            ),
    .hyper_dq_o           ( hyper_dq_o            ),
    .hyper_dq_oe_o        ( hyper_dq_oe_o   ),
    .hyper_reset_no       ( hyper_reset_no  )
  );

  wire        rwds;
  wire [7:0 ] dq_io;

  int i;

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

  always begin
      clk_i = 1;
      #(TCLK/2);
      clk_i = 0;
      #(TCLK/2);
  end

  int expectedResultAt05FFF3[16] = '{16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h1001, 16'h2002, 16'h3003};
  int expectedResultAll1234[8] = '{default: 16'h1234};

  int writeData8[8] = '{16'h1001, 16'h2002, 16'h3003, 16'h40FF, 16'h5555, 16'h6006, 16'h7007, 16'h8008};
  logic [1:0] maskAll8[8] = '{3: 2'b01, 4: 2'b10, default: 2'b00 };
  int expectedResultWrite[8] = '{16'h1001, 16'h2002, 16'h3003, 16'h4004, 16'h0055, 16'h6006, 16'h7007, 16'h8008};

  int writeData64[64] = '{16'h0f00, 16'h0f01, 16'h0f02, 16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h0000, 16'h1001, 16'h2002, 16'h3003, 16'h4004, 16'h5005, 16'h6006, 16'h7007, 16'h8008, 16'h9009, 16'ha00a, 16'hb00b, 16'hc00c, 16'hd00d, 16'he00e, 16'hf00f, 16'h0f00, 16'h0f01, 16'h0f02, 16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h0000, 16'h1001, 16'h2002, 16'h3003, 16'h4004, 16'h5005, 16'h6006, 16'h7007, 16'h8008, 16'h9009, 16'ha00a, 16'hb00b, 16'hc00c, 16'hd00d, 16'he00e, 16'hf00f};
  logic [1:0] mask64[64] = '{14: 2'b01, 43: 2'b10, default: 2'b00 };
  int regWriteData[1] = '{16'h8f1f};
  int regWriteData2[1] = '{16'h0002};

  program test_hyper_phy;
    // SystemVerilog "clocking block"
    // Clocking outputs are DUT inputs and vice versa
    default clocking cb_hyper_phy @(posedge clk_i);
      default input #1step output #1ns;
      output negedge rst_ni;

      output trans_valid_i, trans_address_i, trans_cs_i, trans_write_i, trans_burst_i, trans_address_space_i;
      input trans_ready_o;

      output tx_valid_i, tx_data_i, tx_strb_i;
      input tx_ready_o;

      output rx_ready_i;
      input rx_valid_o, rx_data_o;
    endclocking

    // Apply the test stimulus
    initial begin
      $sdf_annotate("../models/s27ks0641/s27ks0641.sdf", hyperram_model); 

      // Set all inputs at the beginning    
      trans_valid_i = 0;
      trans_address_i = 0;
      trans_cs_i = 0;
      trans_write_i = 0;
      trans_burst_i = 0;
      trans_address_space_i = 0;

      tx_valid_i = 0;
      tx_data_i = 0;
      tx_strb_i = 0;
      rx_ready_i = 0;


      // Will be applied on negedge of clock!
      cb_hyper_phy.rst_ni <= 0;
      // Will be applied 4ns after the clock!
      ##2 cb_hyper_phy.rst_ni <= 1;

      #150us;

      doReadTransaction(32'h05FFF3, 16, expectedResultAt05FFF3, 3);

      doConfig0Write(16'h8f17);

      doReadTransaction(32'h05FFF3, 16, expectedResultAt05FFF3, 3);
      doWriteTransaction(32'h0, 8, writeData8, maskAll8, 1);

      
      doReadTransaction(32'h0, 8, expectedResultWrite);
      doWriteTransaction(32'h0, 64, writeData64, mask64);
      doReadTransaction(32'h0, 64, writeData64);
      // etc. ... 
      //doWriteTransaction(32'h0, 8, writeData);
      //doReadTransaction(32'h0, 8, writeData);
      //doWriteTransaction(32'h111111, 8, writeData);
      //doReadTransaction(32'h0, 8, writeData);

      ##100;     
    end
    // Simulation stops automatically when both initials have been completed
  
    task doReadTransaction(logic[31:0] address, int burst, int expectedResult[] = '{default: 16'b0}, int interruptReadyAt = -1, logic address_space = 0);
      cb_hyper_phy.trans_address_i <= address;
      cb_hyper_phy.trans_burst_i <= burst;
      cb_hyper_phy.trans_write_i <= 0;
      cb_hyper_phy.trans_cs_i <= 2'b01;
      cb_hyper_phy.trans_address_space_i <= address_space;
      cb_hyper_phy.trans_valid_i <= 1;
      wait(cb_hyper_phy.trans_ready_o);
      cb_hyper_phy.trans_valid_i <= 0;

      //read data from phy
      cb_hyper_phy.rx_ready_i <= 1;
      wait(cb_hyper_phy.rx_valid_o);

      i = 0;
      while(i<burst) begin

        if(interruptReadyAt == i) begin
          cb_hyper_phy.rx_ready_i <= 0;
          ##2;
          cb_hyper_phy.rx_ready_i <= 1;
        end 

        if(cb_hyper_phy.rx_valid_o) begin
          $display("Data at address %h is %h, expected %4h", address+i, cb_hyper_phy.rx_data_o, expectedResult[i]);
          assert(cb_hyper_phy.rx_data_o == expectedResult[i]);
          i++;
        end

        ##2; //One clock in clk0
      end

      cb_hyper_phy.rx_ready_i <= 0;

    endtask : doReadTransaction

    task doWriteTransaction(logic [31:0] address, int burst, int data[], logic [1:0] mask[], int interruptValidAt = -1, logic address_space = 0);
      
      cb_hyper_phy.trans_address_i <= address;
      cb_hyper_phy.trans_burst_i <= burst;
      cb_hyper_phy.trans_write_i <= 1;
      cb_hyper_phy.trans_cs_i <= 2'b01;
      cb_hyper_phy.trans_address_space_i <= address_space;

      cb_hyper_phy.trans_valid_i <= 1;
      wait(cb_hyper_phy.trans_ready_o);
      cb_hyper_phy.trans_valid_i <= 0;
      wait(~cb_hyper_phy.trans_ready_o);

      for(i = 0; i < burst; i++) begin
        cb_hyper_phy.tx_data_i <= data[i];
        cb_hyper_phy.tx_strb_i <= mask[i];
        cb_hyper_phy.tx_valid_i <= 1'b1;
        wait(cb_hyper_phy.tx_ready_o);

        if(interruptValidAt == i) begin
            cb_hyper_phy.tx_valid_i <= 1'b0;
            ##30;
            cb_hyper_phy.tx_valid_i <= 1'b1;
        end

        ##2; //Wait one cycle of clk0
      end
      cb_hyper_phy.tx_valid_i <= 1'b0;

    endtask : doWriteTransaction

    task doConfig0Write(logic [15:0] data);
        doWriteTransaction(32'h00000800, 1, '{data}, '{2'b00}, -1 , 1); //set variable latency
    endtask : doConfig0Write

  endprogram

endmodule
