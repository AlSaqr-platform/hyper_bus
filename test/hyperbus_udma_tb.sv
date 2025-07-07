// Hyperbus w/ uDMA Testbench

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Authors: Thomas Benz <tbenz@iis.ee.ethz.ch>
///          Luca Valente <luca.valente@unibo.it>

`timescale 1 ns/1 ps

module hyperbus_udma_tb;

    localparam NumPhys=2;
    localparam NumChips=4;
    localparam MemBaseAddr='h8000_0000;

    fixture_hyperbus_udma #(.NumChips(NumChips), .NumPhys(NumPhys), .MemBaseAddr(MemBaseAddr) ) fix ();

    logic error;

    bit [31:0] delay;

    initial begin
        fix.reset_end();
        #500us;
        fix.i_rmaster.send_write('h1 << 'h2, 'h1, '1, error); // cfg_reg: en_latency_additional

        if ($value$plusargs ("RX_DELAY=%d", delay))
          fix.i_rmaster.send_write('h4 << 'h2, delay, '1, error); // cfg_reg: t_rx_clk_delay

        for(int i = 0; i<32; i = i+1) begin
           fix.i_rmaster.send_write('h100 + i, 'b1100, '1, error);
        end

        #200ns;

        $display("=================");
        $display("128 BIT MEGABURST");
        $display("=================");

        // 128 bit access (burst, extrawide --> will be split)
        fix.write_axi(MemBaseAddr + 'ha00, 4090, 4, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 4090, 4);

        $display("=================");
        $display("128 BIT BURSTS");
        $display("=================");

        // 128 bit access (burst)
        fix.write_axi(MemBaseAddr + 'h110, 3, 4, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h110, 3, 4);

        $display("=================");
        $display("64 BIT MEGABURST ");
        $display("=================");

        // 128 bit access (burst, extrawide --> will be split)
        fix.write_axi(MemBaseAddr + 'ha00, 4090, 3, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 4090, 3);

        $display("=================");
        $display("64 BIT BURSTS");
        $display("=================");

        // TODO (unaligned xfers not yet supported): narrow 64 bit burst
        fix.write_axi(MemBaseAddr + 'h210, 0, 3, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h210, 0, 3);

        // wide 64 bit burst
        fix.write_axi(MemBaseAddr + 'h228, 3, 3, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h228, 3, 3);

        #1471ns;

        $display("=================");
        $display("32 BIT MEGABURST ");
        $display("=================");

        // 128 bit access (burst, extrawide --> will be split)
        fix.write_axi(MemBaseAddr + 'ha00, 4090, 2, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 4090, 2);

        $display("=================");
        $display("32 BIT BURSTS");
        $display("=================");

        // narrow 32 bit burst
        fix.write_axi(MemBaseAddr + 'h304, 1, 2, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h304, 1, 2);

        // wide 32 bit burst
        fix.write_axi(MemBaseAddr + 'h314, 5, 2, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h314, 5, 2);

        $display("=================");
        $display("16 BIT BURSTS");
        $display("=================");

        // wide 16 bit burst
        fix.write_axi(MemBaseAddr + 'h410, 18, 1, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h410, 18, 1);

        // narrow 16 bit burst
        fix.write_axi(MemBaseAddr + 'h402, 5, 1, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h402, 5, 1);

        // wide 16 bit burst
        fix.write_axi(MemBaseAddr + 'h470, 5, 1, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h470, 5, 1);

        // narrow 16 bit burst
        fix.write_axi(MemBaseAddr + 'h452, 6, 1, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h452, 6, 1);

        $display("=================");
        $display("8 BIT BURSTS");
        $display("=================");

        // narrow 8 bit burst
        fix.write_axi(MemBaseAddr + 'h500, 5, 0, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h500, 5, 0);

        // wide 8 bit burst
        fix.write_axi(MemBaseAddr + 'h513, 25, 0, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'h513, 25, 0);

        $display("=================");
        $display("128 BIT ALIGNED ACCESSES");
        $display("=================");

        // 128 bit access
        fix.write_axi(MemBaseAddr + 'h100, 0, 4, 'hbad0_beef_cafe_dead_b00b_8888_7777_aa55, 'hffff);
        fix.read_axi(MemBaseAddr + 'h100, 0, 4);

        $display("=================");
        $display("64 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi(MemBaseAddr + 'h00, 0, 3, 0, 'h00ff);
        fix.write_axi(MemBaseAddr + 'h08, 0, 3, 0, 'hff00);

        fix.read_axi(MemBaseAddr + 'h00, 0, 3);
        fix.read_axi(MemBaseAddr + 'h08, 0, 3);

        #2557ns;

        for(int p; p<100; p++) begin
          fix.write_axi(MemBaseAddr + p*8, 0, 3, 0, 'hffff);
          fix.read_axi(MemBaseAddr + p*8, 0, 3);
        end

        // clean up
        fix.write_axi(MemBaseAddr + 'h00, 100, 3, 1, 'hffff);
        fix.read_axi(MemBaseAddr + 'h0, 100, 3);


        $display("=================");
        $display("32 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi(MemBaseAddr + 'h10, 0, 2, 0, 'h000f);
        fix.write_axi(MemBaseAddr + 'h14, 0, 2, 0, 'h00f0);
        fix.write_axi(MemBaseAddr + 'h18, 0, 2, 0, 'h0f00);
        fix.write_axi(MemBaseAddr + 'h1c, 0, 2, 0, 'hf000);

        fix.read_axi(MemBaseAddr + 'h10, 0, 2);
        fix.read_axi(MemBaseAddr + 'h14, 0, 2);
        fix.read_axi(MemBaseAddr + 'h18, 0, 2);
        fix.read_axi(MemBaseAddr + 'h1c, 0, 2);

        $display("=================");
        $display("16 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi(MemBaseAddr + 'h20, 0, 1, 0, 'h0003);
        fix.write_axi(MemBaseAddr + 'h22, 0, 1, 0, 'h000c);
        fix.write_axi(MemBaseAddr + 'h24, 0, 1, 0, 'h0030);
        fix.write_axi(MemBaseAddr + 'h26, 0, 1, 0, 'h00c0);
        fix.write_axi(MemBaseAddr + 'h28, 0, 1, 0, 'h0300);
        fix.write_axi(MemBaseAddr + 'h2a, 0, 1, 0, 'h0c00);
        fix.write_axi(MemBaseAddr + 'h2c, 0, 1, 0, 'h3000);
        fix.write_axi(MemBaseAddr + 'h2e, 0, 1, 0, 'hc000);

        fix.read_axi(MemBaseAddr + 'h20, 0, 1);
        fix.read_axi(MemBaseAddr + 'h22, 0, 1);
        fix.read_axi(MemBaseAddr + 'h24, 0, 1);
        fix.read_axi(MemBaseAddr + 'h26, 0, 1);
        fix.read_axi(MemBaseAddr + 'h28, 0, 1);
        fix.read_axi(MemBaseAddr + 'h2a, 0, 1);
        fix.read_axi(MemBaseAddr + 'h2c, 0, 1);
        fix.read_axi(MemBaseAddr + 'h2e, 0, 1);

        $display("=================");
        $display("8 BIT ALIGNED ACCESSES");
        $display("=================");

        fix.write_axi(MemBaseAddr + 'h30, 0, 0, 0, 'h0001);
        fix.write_axi(MemBaseAddr + 'h31, 0, 0, 0, 'h0002);
        fix.write_axi(MemBaseAddr + 'h32, 0, 0, 0, 'h0004);
        fix.write_axi(MemBaseAddr + 'h33, 0, 0, 0, 'h0008);
        fix.write_axi(MemBaseAddr + 'h34, 0, 0, 0, 'h0010);
        fix.write_axi(MemBaseAddr + 'h35, 0, 0, 0, 'h0020);
        fix.write_axi(MemBaseAddr + 'h36, 0, 0, 0, 'h0040);
        fix.write_axi(MemBaseAddr + 'h37, 0, 0, 0, 'h0080);
        fix.write_axi(MemBaseAddr + 'h38, 0, 0, 0, 'h0100);
        fix.write_axi(MemBaseAddr + 'h39, 0, 0, 0, 'h0200);
        fix.write_axi(MemBaseAddr + 'h3a, 0, 0, 0, 'h0400);
        fix.write_axi(MemBaseAddr + 'h3b, 0, 0, 0, 'h0800);
        fix.write_axi(MemBaseAddr + 'h3c, 0, 0, 0, 'h1000);
        fix.write_axi(MemBaseAddr + 'h3d, 0, 0, 0, 'h2000);
        fix.write_axi(MemBaseAddr + 'h3e, 0, 0, 0, 'h4000);
        fix.write_axi(MemBaseAddr + 'h3f, 0, 0, 0, 'h8000);

        fix.read_axi(MemBaseAddr + 'h30, 0, 0);
        fix.read_axi(MemBaseAddr + 'h31, 0, 0);
        fix.read_axi(MemBaseAddr + 'h32, 0, 0);
        fix.read_axi(MemBaseAddr + 'h33, 0, 0);
        fix.read_axi(MemBaseAddr + 'h34, 0, 0);
        fix.read_axi(MemBaseAddr + 'h35, 0, 0);
        fix.read_axi(MemBaseAddr + 'h36, 0, 0);
        fix.read_axi(MemBaseAddr + 'h37, 0, 0);
        fix.read_axi(MemBaseAddr + 'h38, 0, 0);
        fix.read_axi(MemBaseAddr + 'h39, 0, 0);
        fix.read_axi(MemBaseAddr + 'h3a, 0, 0);
        fix.read_axi(MemBaseAddr + 'h3b, 0, 0);
        fix.read_axi(MemBaseAddr + 'h3c, 0, 0);
        fix.read_axi(MemBaseAddr + 'h3d, 0, 0);
        fix.read_axi(MemBaseAddr + 'h3e, 0, 0);
        fix.read_axi(MemBaseAddr + 'h3f, 0, 0);

        $display("=================");
        $display("COMBINED");
        $display("=================");

        fix.write_axi(MemBaseAddr + 'h800, 0, 4, 1, 'hffff);
        fix.read_axi(MemBaseAddr + 'h800, 0, 4);
        fix.write_axi(MemBaseAddr + 'h800, 0, 4, 0, 'hc03f);
        fix.read_axi(MemBaseAddr + 'h800, 0, 4);
        fix.write_axi(MemBaseAddr + 'h806, 0, 1, 0, 'h00c0);
        fix.write_axi(MemBaseAddr + 'h80a, 0, 1, 0, 'h0c00);
        fix.write_axi(MemBaseAddr + 'h80e, 0, 1, 0, 'hc000);
        fix.read_axi(MemBaseAddr + 'h806, 0, 1);
        fix.read_axi(MemBaseAddr + 'h80a, 0, 1);
        fix.read_axi(MemBaseAddr + 'h80e, 0, 1);

        $display("=================");
        $display("UNALIGNED");
        $display("=================");

        fix.write_axi(MemBaseAddr + 'h900, 10, 4, 1, 'hffff);
        fix.read_axi(MemBaseAddr + 'h900, 10, 4);

        // 32b inner 3-burst on 16b boundary
        fix.write_axi(MemBaseAddr + 'h902, 2, 2, 0, 'hF0FF);
        fix.read_axi(MemBaseAddr + 'h902, 2, 2);

        // 32b outer 10-burst on 16b boundary
        fix.write_axi(MemBaseAddr + 'h90a, 9, 2, 0, 'hF0FF);
        fix.read_axi(MemBaseAddr + 'h90a, 9, 2);

        // 64b inner single on 16b boundary
        fix.write_axi(MemBaseAddr + 'h910, 10, 3, 1, 'hffff);
        fix.read_axi(MemBaseAddr + 'h910, 10, 3);
        fix.write_axi(MemBaseAddr + 'h91C, 0, 3, 0, 'hFF0F);
        fix.read_axi(MemBaseAddr + 'h91C, 0, 3);

        // 64b inner 5-burst on 16b boundary
        fix.write_axi(MemBaseAddr + 'h990, 5, 3, 1, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h990, 5, 3);
        fix.write_axi(MemBaseAddr + 'h992, 4, 3, 0, 'hFF0F);
        fix.read_axi(MemBaseAddr + 'h992, 4, 3);

        // 64b inner single on 32b boundary
        fix.write_axi(MemBaseAddr + 'h924, 0, 3, 0, 'hF0FF);
        fix.read_axi(MemBaseAddr + 'h924, 0, 3);

        // 128 outer single on 16b boundary (read back in aligned fasion)
        fix.write_axi(MemBaseAddr + 'h930, 0, 4, 0, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h930, 0, 4);

        fix.write_axi(MemBaseAddr + 'h954, 0, 4, 1, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h954, 0, 4);

        // 128 outer single on 32b boundary (read back in aligned fasion)
        fix.write_axi(MemBaseAddr + 'h954, 0, 4, 0, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h954, 0, 4);


        // 128 outer single on 64b boundary (read back in aligned fasion)
        fix.write_axi(MemBaseAddr + 'h978, 0, 4, 1, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h978, 0, 4); //siamo qua
        // 128 outer single on 64b boundary (read back in aligned fasion)
        fix.write_axi(MemBaseAddr + 'h978, 0, 4, 0, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h978, 0, 4);

        // 128 5-burst single on 16b boundary (read back in aligned fasion) //here
        fix.write_axi(MemBaseAddr + 'h1c02, 4, 4, 0, 'hFFFF);
        fix.read_axi(MemBaseAddr + 'h1c02, 4, 4);

        // 128 bit access (burst, extrawide --> will be split)
        fix.write_axi(MemBaseAddr + 'ha00, 4090, 4, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 4090, 4);

        // 64 bit access (burst, extrawide --> will be split)
        fix.write_axi(MemBaseAddr + 'ha00, 4090, 3, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 4090, 3);

        // 32 bit access (burst, extrawide --> will be split)
        fix.write_axi(MemBaseAddr + 'ha00, 4090, 2, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 4090, 2);

        $display("======================");
        $display("AXI DONE WITH SUCCESS!");
        $display("======================");

        fix.LongWriteTransactionTest(MemBaseAddr + 1, 0,'h200,0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 2, 76,'h10,0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 8, 6,'h11,0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 28, 32,'h22,0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 70, 5,'h3, 0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 100, 8,'h4,0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 50, 65,'h14,0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 90, 16,'h7, 0);
        #8us;

        fix.LongWriteTransactionTest(MemBaseAddr + 0, 128,'h100,0);
        #8us;

        $display("======================");
        $display("UDMA DONE...");
        $display("======================");

        // 32 bit access
        fix.write_axi(MemBaseAddr + 'ha00, 2, 2, 0, 'hffff);
        fix.read_axi(MemBaseAddr + 'ha00, 2, 2);

        $display("======================");
        $display("AND WITH NO TIME OUTS!");
        $display("======================");

        #5us;
        $stop();
    end

endmodule : hyperbus_udma_tb
