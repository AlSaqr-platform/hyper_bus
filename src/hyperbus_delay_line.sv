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

    // assign out = in;

    //assign #(1ns) out = in; 

    // logic [7:0] delay_onehot;
    // assign delay_onehot = 1<<delay;

    // PROGDEL8 progdel8_i (
    //     .A( in           ),
    //     .S( delay_onehot ),
    //     .Z( out          )
    // );

    logic left;
    logic right;


    CKMUX2M2R i_clk_mux_top 
    (
        .A ( left     ),
        .B ( right    ),
        .S ( delay[1] ),
        .Z ( out      )
    );

    CKMUX2M2R i_clk_mux_left 
    (
        .A ( in       ),
        .B ( in       ),
        .S ( delay[0] ),
        .Z ( left     )
    );

    CKMUX2M2R i_clk_mux_right 
    (
        .A ( in       ),
        .B ( in       ),
        .S ( delay[0] ),
        .Z ( right    )
    );

endmodule
