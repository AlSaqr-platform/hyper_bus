// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// Author:
// Date:
// Description: Configuration for hyperbus

module config_registers #(
  parameter NR_CS = 2
)(
    input logic           clk_i,          // Clock
    input logic           rst_ni,         // Asynchronous reset active low

    REG_BUS.in            cfg_i,

    output logic [31:0]   config_t_latency_access,
    output logic [31:0]   config_t_latency_additional,
    output logic [31:0]   config_t_cs_max,
    output logic [31:0]   config_t_read_write_recovery,
    output logic [31:0]   config_addr_mapping_cs0_start,
    output logic [31:0]   config_addr_mapping_cs0_end
);


    //Order or registers is inversed

    reg_uniform #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 ),
        .NUM_REG    ( 6  ),
        .REG_WIDTH  ( 32 )
    ) registers (
        .clk_i      ( clk_i ),
        .rst_ni     ( rst_ni ),
        .init_val_i ( {
                32'h3FFFFF,     //config_addr_mapping_cs0_end
                32'h0,          //config_addr_mapping_cs0_start
                32'h6,          //config_t_read_write_recovery
                32'd666,        //config_t_cs_max
                32'h6,          //config_t_latency_additional
                32'h6           //config_t_latency_access
            } ),
        .rd_val_i   ( { config_addr_mapping_cs0_end, config_addr_mapping_cs0_start, config_t_read_write_recovery, config_t_cs_max, config_t_latency_additional, config_t_latency_access } ),
        .wr_val_o   ( { config_addr_mapping_cs0_end, config_addr_mapping_cs0_start, config_t_read_write_recovery, config_t_cs_max, config_t_latency_additional, config_t_latency_access } ),
        .reg_i      ( cfg_i )
    );


endmodule
