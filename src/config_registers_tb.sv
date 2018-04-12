// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

module config_registers_tb;

    localparam TCLK = 3ns;
    localparam NR_CS = 2;

    logic             clk_i = 0;         
    logic             rst_ni = 1;

    logic [31:0]      config_t_latency_access;
    logic [31:0]      config_t_latency_additional;
    logic [31:0]      config_t_cs_max;
    logic [31:0]      config_t_read_write_recovery;
    logic [31:0]      config_addr_mapping_cs0_start;
    logic [31:0]      config_addr_mapping_cs0_end;

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) cfg_i(clk_i);

    typedef reg_test::reg_driver #(
        .AW ( 32       ),
        .DW ( 32       ),
        .TA ( TCLK*0.2 ),
        .TT ( TCLK*0.8 )
    ) cfg_driver_t;

    cfg_driver_t cfg_drv = new(cfg_i);

    logic done = 0;


    config_registers #(
        .NR_CS(2)
    ) dut (
        .clk_i                         ( clk_i                         ),
        .rst_ni                        ( rst_ni                        ),
        .cfg_i                         ( cfg_i                         ),
        .config_t_latency_access       ( config_t_latency_access       ),
        .config_t_latency_additional   ( config_t_latency_additional   ),
        .config_t_cs_max               ( config_t_cs_max               ),
        .config_t_read_write_recovery  ( config_t_read_write_recovery  ),
        .config_addr_mapping_cs0_start ( config_addr_mapping_cs0_start ),
        .config_addr_mapping_cs0_end   ( config_addr_mapping_cs0_end   )
    );

    initial begin
        repeat(3) #TCLK;
        rst_ni = 0;
        repeat(3) #TCLK;
        rst_ni = 1;
        #TCLK;
        while (!done) begin
            clk_i = 1;
            #(TCLK/2);
            clk_i = 0;
            #(TCLK/2);
        end
    end

    initial begin
        automatic logic [31:0] data;
        automatic logic error;

        @(negedge rst_ni);
        cfg_drv.reset_master();
        @(posedge rst_ni);
        repeat(3) @(posedge clk_i);

        // Access the register interface.
        cfg_drv.send_write('h4, 'h3, '1, error);
        repeat(3) @(posedge clk_i);
        cfg_drv.send_read('h4, data, error);
        assert(data == 'h3);
        repeat(3) @(posedge clk_i);

        cfg_drv.send_read('h8, data, error);
        assert(data == 'h29a);
        repeat(3) @(posedge clk_i);

        cfg_drv.send_read('h10, data, error);
        assert(data == '0);
        repeat(3) @(posedge clk_i);

        cfg_drv.send_read('h0, data, error);
        assert(data == 'h6);
        repeat(3) @(posedge clk_i);



        repeat(10) @(posedge clk_i);
        done = 1;

    end

endmodule
