// Hyperbus Testbench

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>


module hyperbus_tb;

    fixture_hyperbus #(.NumChips(2)) fix ();

    initial begin
        fix.reset_end();
        #150us;
        #200ns;
        fix.write_axi('h100, 'h0, 'hbeef, '1 );
        fix.read_axi('h100, 'h0);
        #500ns;
        $stop();
    end

endmodule : hyperbus_tb
