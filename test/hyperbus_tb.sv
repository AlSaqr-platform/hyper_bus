// Hyperbus Testbench

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>


module hyperbus_tb;

    fixture_hyperbus #(.NumChips(2)) fix ();

    logic error;

    initial begin
        fix.reset_end();
        #150us;
        // fix.i_rmaster.send_write('h4, 'h1, '1, error);
        // #200ns;
        // fix.write_axi('h00, 'h0, 'hcafecafebeefb0081234abcdaa55f0f0, 'hff00 );
        // fix.read_axi('h00, 'h0);
        fix.start_rand_master(100, 100);
        #5us;
        $stop();
    end

endmodule : hyperbus_tb
