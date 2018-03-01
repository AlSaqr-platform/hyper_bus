// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

module hyperbus_tb;

  localparam TCLK = 6ns;
  localparam NR_CS = 2;

  logic             clk_i = 0;         
  logic             rst_ni = 1;

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

endmodule
