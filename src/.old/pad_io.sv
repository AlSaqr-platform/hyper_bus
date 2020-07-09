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
    input  logic             oe_i, //high output, low input
    output logic [WIDTH-1:0] data_o,
    inout  wire  [WIDTH-1:0] pad_io
);

`define pads_iumb

`ifdef pads_iumb
    genvar i;
    generate
      for(i=0; i<WIDTH; i++)
      begin: pad_io_buf
        IUMB iumb_i (
            .DO(data_i[i]),
            .DI(data_o[i]),
            .PAD(pad_io[i]),
            .OE(oe_i),
            .IDDQ(1'b0),
            .PIN2(1'b0),
            .PIN1(1'b0),
            .SMT(1'b0),
            .PD(1'b0),
            .PU(1'b0),
            .SR(1'b0)
        );
      end
    endgenerate
`else 
    logic [WIDTH-1:0] out;

    assign #2000 data_o = pad_io;

    //split delay, delay above 3ns doesn't work
    assign #3000 out = (oe_i) ? data_i : 8'bz;

    assign #2000 pad_io = out;
`endif

endmodule
