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
        fix.i_rmaster.send_write('h4, 'h1, '1, error);
        #200ns;
        fix.write_axi('h00, 'h0, 'h0102030405060708090a0b0c0d0e0f, '1 );
        fix.read_axi('h00, 0);
        #500ns;
        $stop();
    end

endmodule : hyperbus_tb
