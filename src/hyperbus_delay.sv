// Hyperbus delay

// this code is unstable and most likely buggy
// it should not be used by anyone

// Author: Thomas Benz <paulsc@iis.ee.ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>

module hyperbus_delay (
    input  logic in_i,
    output logic out_o
);

    assign #(1.5ns) out_o = in_i;

endmodule : hyperbus_delay 
