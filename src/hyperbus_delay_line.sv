// Copyright (C) 2017-2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

/// A single to double data rate converter.
`timescale 1 ps/1 ps

module hyperbus_delay_line (
    input        in,
    output       out,
    input [31:0] delay
);

    assign #(delay) out = in; 


endmodule