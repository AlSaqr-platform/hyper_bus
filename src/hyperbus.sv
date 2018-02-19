// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// Author:
// Date:
// Description:

module hyperbus (
    input logic        clk_i,    // Clock
    input logic        rst_ni,   // Asynchronous reset active low

    output logic       ck_o,
    output logic       ck_no,
    output logic       cs_no,
    output logic       wp_no,
    output logic       hwreset_no,
    input  logic       rds_i,
    inout  logic [7:0] dq_io,
    input  logic       int_ni,
    input  logic       rsto_ni
);

endmodule