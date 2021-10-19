// Hyperbus Testbench

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Authors: Thomas Benz <tbenz@iis.ee.ethz.ch>
///          Luca Valente <luca.valente@unibo.it>


module hyperbus_tb;

    fixture_hyperbus #(.NumChips(2)) fix ();

    logic error;

    initial begin
        fix.reset_end();
        #500us;
        fix.i_rmaster.send_write('h4, 'h1, '1, error);

        #200ns;

        $display("=================");
        $display("128 BIT MEGABURST");
        $display("=================");

        // 128 bit access (burst, extrawide --> will be split)
        fix.write_axi('ha00, 4090, 4, 'h1234_5678_9abc_def0_7766_5544_3322_1100, 'hffff);
        fix.read_axi('ha00, 4090, 4);

        $display("=================");
        $display("128 BIT BURSTS");
        $display("=================");

        // 128 bit access (burst)
        fix.write_axi('h110, 3, 4, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h110, 3, 4);

        $display("=================");
        $display("64 BIT BURSTS");
        $display("=================");

        // TODO (unaligned xfers not yet supported): narrow 64 bit burst
        fix.write_axi('h210, 0, 3, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
        fix.read_axi('h210, 0, 3);

        // wide 64 bit burst
        fix.write_axi('h228, 3, 3, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h228, 3, 3);

        #1471ns;

        $display("=================");
        $display("32 BIT BURSTS");
        $display("=================");

        // narrow 32 bit burst
        fix.write_axi('h304, 1, 2, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
        fix.read_axi('h304, 1, 2);

        // wide 32 bit burst
        fix.write_axi('h314, 5, 2, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h314, 5, 2);

        $display("=================");
        $display("16 BIT BURSTS");
        $display("=================");
  
        // wide 16 bit burst
        fix.write_axi('h410, 18, 1, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h410, 18, 1);
       
        // narrow 16 bit burst
        fix.write_axi('h402, 5, 1, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
        fix.read_axi('h402, 5, 1);
       
        // wide 16 bit burst
        fix.write_axi('h470, 5, 1, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h470, 5, 1);  
     
        // narrow 16 bit burst
        fix.write_axi('h452, 6, 1, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
        fix.read_axi('h452, 6, 1);

        $display("=================");
        $display("128 BIT BURSTS");
        $display("=================");

        // 128 bit access (burst)
        fix.write_axi('h110, 3, 4, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h110, 3, 4);
       
        $display("=================");
        $display("8 BIT BURSTS");
        $display("=================");

        // narrow 8 bit burst
        fix.write_axi('h500, 5, 0, 'h11ee_ddcc_bbaa_9988_7766_5544_3322_1100, 'hffff);
        fix.read_axi('h500, 5, 0);

        // wide 8 bit burst
        fix.write_axi('h513, 25, 0, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h513, 25, 0);

        $display("=================");
        $display("128 BIT ALIGNED ACCESSES");
        $display("=================");

        // 128 bit access
        fix.write_axi('h100, 0, 4, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi('h100, 0, 4);

        $display("=================");
        $display("64 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi('h00, 0, 3, 'h5555_5555_5555_5555_4444_3333_2222_1111, 'h00ff);
        fix.write_axi('h08, 0, 3, 'h9999_8888_7777_6666_5555_5555_5555_5555, 'hff00);

        fix.read_axi('h00, 0, 3);
        fix.read_axi('h08, 0, 3);

        #2557ns;

        $display("=================");
        $display("32 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi('h10, 0, 2, 'hffff_ffff_ffff_ffff_ffff_ffff_cafe_beef, 'h000f);
        fix.write_axi('h14, 0, 2, 'hffff_ffff_ffff_ffff_cafe_beef_ffff_ffff, 'h00f0);
        fix.write_axi('h18, 0, 2, 'hffff_ffff_cafe_beef_ffff_ffff_ffff_ffff, 'h0f00);
        fix.write_axi('h1c, 0, 2, 'hcafe_beef_ffff_ffff_ffff_ffff_ffff_ffff, 'hf000);

        fix.read_axi('h10, 0, 2);
        fix.read_axi('h14, 0, 2);
        fix.read_axi('h18, 0, 2);
        fix.read_axi('h1c, 0, 2);

        $display("=================");
        $display("16 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi('h20, 0, 1, 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_beef, 'h0003);
        fix.write_axi('h22, 0, 1, 'hffff_ffff_ffff_ffff_ffff_ffff_beef_ffff, 'h000c);
        fix.write_axi('h24, 0, 1, 'hffff_ffff_ffff_ffff_ffff_beef_ffff_ffff, 'h0030);
        fix.write_axi('h26, 0, 1, 'hffff_ffff_ffff_ffff_beef_ffff_ffff_ffff, 'h00c0);
        fix.write_axi('h28, 0, 1, 'hffff_ffff_ffff_beef_ffff_ffff_ffff_ffff, 'h0300);
        fix.write_axi('h2a, 0, 1, 'hffff_ffff_beef_ffff_ffff_ffff_ffff_ffff, 'h0c00);
        fix.write_axi('h2c, 0, 1, 'hffff_beef_ffff_ffff_ffff_ffff_ffff_ffff, 'h3000);
        fix.write_axi('h2e, 0, 1, 'hbeef_ffff_ffff_ffff_ffff_ffff_ffff_ffff, 'hc000);

        fix.read_axi('h20, 0, 1);
        fix.read_axi('h22, 0, 1);
        fix.read_axi('h24, 0, 1);
        fix.read_axi('h26, 0, 1);
        fix.read_axi('h28, 0, 1);
        fix.read_axi('h2a, 0, 1);
        fix.read_axi('h2c, 0, 1);
        fix.read_axi('h2e, 0, 1);

        $display("=================");
        $display("8 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi('h30, 0, 0, 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff20, 'h0001);
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

        $display("=================");
        $display("COMBINED");
        $display("=================");

        fix.write_axi('h800, 0, 4, 'h0000_0000_0000_0000_0000_0000_0000_0000, 'hffff);
        fix.read_axi('h800, 0, 4);
        fix.write_axi('h800, 0, 4, 'hcaca_abba_abba_abba_abba_3214_00aa_ca00, 'hc03f);
        fix.read_axi('h800, 0, 4);
        fix.write_axi('h806, 0, 1, 'hffff_ffff_ffff_ffff_f1f0_ffff_ffff_ffff, 'h00c0);
        fix.write_axi('h80a, 0, 1, 'hffff_ffff_b0b0_ffff_ffff_ffff_ffff_ffff, 'h0c00);
        fix.write_axi('h80e, 0, 1, 'habcd_ffff_ffff_ffff_ffff_ffff_ffff_ffff, 'hc000);
        fix.read_axi('h806, 0, 1);
        fix.read_axi('h80a, 0, 1);
        fix.read_axi('h80e, 0, 1);

        $display("=================");
        $display("UNALIGNED");
        $display("=================");

        fix.write_axi('h900, 10, 4, 'h0000_0000_0000_0000_0000_0000_0000_0000, 'hffff);
        fix.read_axi('h900, 10, 4);

        // 32b inner 3-burst on 16b boundary
        fix.write_axi('h902, 2, 2, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hF0FF);
        fix.read_axi('h902, 2, 2);

        // 32b outer 10-burst on 16b boundary
        fix.write_axi('h90a, 9, 2, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hF0FF);
        fix.read_axi('h90a, 9, 2);

        // 64b inner single on 16b boundary
        fix.write_axi('h91C, 0, 3, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hFF0F);
        fix.read_axi('h91C, 0, 3);

        // 64b inner 5-burst on 16b boundary
        fix.write_axi('h992, 4, 3, 'h0000_0000_0000_0000_0000_0000_0000_0000, 'hFFFF);
        fix.read_axi('h992, 4, 3);
        fix.write_axi('h992, 4, 3, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hFF0F);
        fix.read_axi('h992, 4, 3);

        // 64b inner single on 32b boundary
        fix.write_axi('h924, 0, 3, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hF0FF);
        fix.read_axi('h924, 0, 3);

        // 128 outer single on 16b boundary (read back in aligned fasion)
        fix.write_axi('h930, 0, 4, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hFFFF);
        fix.read_axi('h930, 0, 4);

        fix.write_axi('h954, 0, 4, 'h0000_0000_0000_0000_0000_0000_0000_0000, 'hFFFF);
        fix.read_axi('h954, 0, 4);       
        // 128 outer single on 32b boundary (read back in aligned fasion)
        fix.write_axi('h954, 0, 4, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hFFFF);
        fix.read_axi('h954, 0, 4);
    
        // 128 outer single on 64b boundary (read back in aligned fasion)
        fix.write_axi('h978, 0, 4, 'h0000_0000_0000_0000_0000_0000_0000_0000, 'hFFFF);
        fix.read_axi('h978, 0, 4);
        // 128 outer single on 64b boundary (read back in aligned fasion)
        fix.write_axi('h978, 0, 4, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hFFFF);
        fix.read_axi('h978, 0, 4);

        // 128 5-burst single on 16b boundary (read back in aligned fasion)
        fix.write_axi('h1c02, 4, 4, 'h11ee_ccdd_bbaa_9988_7766_5544_3322_1100, 'hFFFF);
        fix.read_axi('h1c02, 4, 4);

        $display("==================");
        $display("DONE WITH SUCCESS!");
        $display("==================");


        #5us;
        $stop();
    end

endmodule : hyperbus_tb
