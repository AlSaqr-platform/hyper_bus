// Copyright (C) 2017-2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

module pad_simulation (
    input  logic data_i,
    input  logic oe_i,
    output logic data_o,
    inout  logic pad_io
);

	assign data_o = pad_io;

	assign pad_io = oe_i ? data_i : 1'bz;

endmodule
