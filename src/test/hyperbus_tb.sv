// Hyperbus Testbench

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>


module hyperbus_tb;

    fixture_hyperbus #(.AxiAw(32), .AxiDw(64), .AxiIw(6), .NumChips(2)) fix ();

    initial begin
        fix.reset_end();
        #200ns;
        $stop();
    end

endmodule : hyperbus_tb
