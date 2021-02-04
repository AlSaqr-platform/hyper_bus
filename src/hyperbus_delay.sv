// Hyperbus delay

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <paulsc@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

// TODO: properly include generic_delay once it is a full IP or integrated in one

module hyperbus_delay (
    input  logic        in_i,
    input  logic [3:0]  delay_i,
    output logic        out_o
);

    logic [1:0] out;

    generic_delay i_delay (
        .clk_i      ( in_i      ),
        .enable_i   ( 1'b1      ),
        .delay_i    ( delay_i   ),
        .clk_o      ( out       )
    );

    assign out_o = out[1];

endmodule : hyperbus_delay
