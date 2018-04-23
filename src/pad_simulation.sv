// Copyright (C) 2017-2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

`timescale 1ps/1ps

module pad_io #(
  parameter WIDTH = 1
  )(
    input  logic [WIDTH-1:0] data_i,
    input  logic             oe_i,
    output logic [WIDTH-1:0] data_o,
    inout  logic [WIDTH-1:0] pad_io
);

    logic [WIDTH-1:0] out;

    assign #2000 data_o = pad_io;

    //split delay, delay above 3ns doesn't work
    assign #3000 out = (oe_i) ? data_i : 8'bz;

    assign #2000 pad_io = out;

endmodule
