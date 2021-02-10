// Hyperbus Testbench

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>


module hyperbus_tb;

    fixture_hyperbus #(.NumChips(2)) fix ();

    logic error;

    initial begin
        fix.reset_end();
        #500us;
        fix.i_rmaster.send_write('h4, 'h1, '1, error);

        #200ns;
        fix.write_axi('h800, 0, 4, 'hcaca_ffff_ffff_ffff_ffff_3214_00aa_ca00, 'hc03f);
        fix.write_axi('h808, 0, 1, 'hffff_ffff_ffff_dd11_ffff_ffff_ffff_ffff, 'h0300);
        fix.write_axi('h80c, 0, 1, 'hffff_22dd_ffff_ffff_ffff_ffff_ffff_ffff, 'h3000);
        fix.write_axi('h800, 0, 1, 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffe1, 'h0001);  // TODO: Used to be BYTE access (size 0)
        fix.read_axi('h800, 0, 4);
        fix.write_axi('h806, 0, 1, 'hffff_ffff_ffff_ffff_f1f0_ffff_ffff_ffff, 'h00c0);
        fix.write_axi('h80a, 0, 1, 'hffff_ffff_b0b0_ffff_ffff_ffff_ffff_ffff, 'h0c00);
        fix.write_axi('h80e, 0, 1, 'habcd_ffff_ffff_ffff_ffff_ffff_ffff_ffff, 'hc000);
        fix.read_axi('h800, 0, 4);
        fix.read_axi('h800, 0, 4);

        //fix.start_rand_master(0, 5);
        //fix.start_rand_master(20, 0);

        // TODO: Bursts stuck at end --> investigate why!

        // 128 bit access (burst)
        //fix.write_axi('ha00, 127, 4, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
       // fix.read_axi('ha00, 127, 4);

        // 128 bit access (burst, extrawide --> will be split)
        //fix.write_axi('ha00, 4090, 4, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
        //fix.read_axi('ha00, 4090, 4);

        // 128 bit access
        fix.write_axi('h100, 0, 4, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h100, 0, 4);

        // 64 bit access (aligned)
        fix.write_axi('h00, 0, 3, 'h5555_5555_5555_5555_4444_3333_2222_1111, 'h00ff);
        fix.write_axi('h08, 0, 3, 'h9999_8888_7777_6666_5555_5555_5555_5555, 'hff00);

        fix.read_axi('h00, 0, 4);
        fix.read_axi('h00, 0, 3);
        fix.read_axi('h08, 0, 3);

        // 32 bit (aligned)
        fix.write_axi('h10, 0, 2, 'hffff_ffff_ffff_ffff_ffff_ffff_cafe_beef, 'h000f);
        fix.write_axi('h14, 0, 2, 'hffff_ffff_ffff_ffff_cafe_beef_ffff_ffff, 'h00f0);
        fix.write_axi('h18, 0, 2, 'hffff_ffff_cafe_beef_ffff_ffff_ffff_ffff, 'h0f00);
        fix.write_axi('h1c, 0, 2, 'hcafe_beef_ffff_ffff_ffff_ffff_ffff_ffff, 'hf000);

        fix.read_axi('h10, 0, 4);
        fix.read_axi('h10, 0, 2);
        fix.read_axi('h14, 0, 2);
        fix.read_axi('h18, 0, 2);
        fix.read_axi('h1c, 0, 2);

        // 16 bit (aligned)
        fix.write_axi('h20, 0, 1, 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_beef, 'h0003);
        fix.write_axi('h22, 0, 1, 'hffff_ffff_ffff_ffff_ffff_ffff_beef_ffff, 'h000c);
        fix.write_axi('h24, 0, 1, 'hffff_ffff_ffff_ffff_ffff_beef_ffff_ffff, 'h0030);
        fix.write_axi('h26, 0, 1, 'hffff_ffff_ffff_ffff_beef_ffff_ffff_ffff, 'h00c0);
        fix.write_axi('h28, 0, 1, 'hffff_ffff_ffff_beef_ffff_ffff_ffff_ffff, 'h0300);
        fix.write_axi('h2a, 0, 1, 'hffff_ffff_beef_ffff_ffff_ffff_ffff_ffff, 'h0c00);
        fix.write_axi('h2c, 0, 1, 'hffff_beef_ffff_ffff_ffff_ffff_ffff_ffff, 'h3000);
        fix.write_axi('h2e, 0, 1, 'hbeef_ffff_ffff_ffff_ffff_ffff_ffff_ffff, 'hc000);

        fix.read_axi('h20, 0, 4);
        fix.read_axi('h20, 0, 1);
        fix.read_axi('h22, 0, 1);
        fix.read_axi('h24, 0, 1);
        fix.read_axi('h26, 0, 1);
        fix.read_axi('h28, 0, 1);
        fix.read_axi('h2a, 0, 1);
        fix.read_axi('h2c, 0, 1);
        fix.read_axi('h2e, 0, 1);

        // TODO: Used to be ENABLED (byte accesses not supported yet)
        /*
        // 8 bit (aligned)
        fix.write_axi('h30, 0, 0, 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff11, 'h0001);
        fix.write_axi('h31, 0, 0, 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_1eff, 'h0002);
        fix.write_axi('h32, 0, 0, 'hffff_ffff_ffff_ffff_ffff_ffff_ff1d_ffff, 'h0004);
        fix.write_axi('h33, 0, 0, 'hffff_ffff_ffff_ffff_ffff_ffff_1cff_ffff, 'h0008);
        fix.write_axi('h34, 0, 0, 'hffff_ffff_ffff_ffff_ffff_ff1b_ffff_ffff, 'h0010);
        fix.write_axi('h35, 0, 0, 'hffff_ffff_ffff_ffff_ffff_1aff_ffff_ffff, 'h0020);
        fix.write_axi('h36, 0, 0, 'hffff_ffff_ffff_ffff_ff19_ffff_ffff_ffff, 'h0040);
        fix.write_axi('h37, 0, 0, 'hffff_ffff_ffff_ffff_18ff_ffff_ffff_ffff, 'h0080);
        fix.write_axi('h38, 0, 0, 'hffff_ffff_ffff_ff17_ffff_ffff_ffff_ffff, 'h0100);
        fix.write_axi('h39, 0, 0, 'hffff_ffff_ffff_16ff_ffff_ffff_ffff_ffff, 'h0200);
        fix.write_axi('h3a, 0, 0, 'hffff_ffff_ff15_ffff_ffff_ffff_ffff_ffff, 'h0400);
        fix.write_axi('h3b, 0, 0, 'hffff_ffff_14ff_ffff_ffff_ffff_ffff_ffff, 'h0800);
        fix.write_axi('h3c, 0, 0, 'hffff_ff13_ffff_ffff_ffff_ffff_ffff_ffff, 'h1000);
        fix.write_axi('h3d, 0, 0, 'hffff_12ff_ffff_ffff_ffff_ffff_ffff_ffff, 'h2000);
        fix.write_axi('h3e, 0, 0, 'hff11_ffff_ffff_ffff_ffff_ffff_ffff_ffff, 'h4000);
        fix.write_axi('h3f, 0, 0, 'h10ff_ffff_ffff_ffff_ffff_ffff_ffff_ffff, 'h8000);


        fix.read_axi('h30, 0, 4);
        fix.read_axi('h30, 0, 0);
        fix.read_axi('h31, 0, 0);
        fix.read_axi('h32, 0, 0);
        fix.read_axi('h33, 0, 0);
        fix.read_axi('h34, 0, 0);
        fix.read_axi('h35, 0, 0);
        fix.read_axi('h36, 0, 0);
        fix.read_axi('h37, 0, 0);
        fix.read_axi('h38, 0, 0);
        fix.read_axi('h39, 0, 0);
        fix.read_axi('h3a, 0, 0);
        fix.read_axi('h3b, 0, 0);
        fix.read_axi('h3c, 0, 0);
        fix.read_axi('h3d, 0, 0);
        fix.read_axi('h3e, 0, 0);
        fix.read_axi('h3f, 0, 0);
        */

        #5us;
        $stop();
    end

endmodule : hyperbus_tb
