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
  parameter NR_CS = 2,
  parameter ADDR_MAPPING_WIDTH = 64 * NR_CS
)(
    input logic           clk_i,          // Clock
    input logic           rst_ni,         // Asynchronous reset active low

    REG_BUS.in            cfg_i,

    output logic [31:0]                     config_t_latency_access,      //Address 'h00
    output logic [31:0]                     config_t_latency_additional,  //Address 'h04
    output logic [31:0]                     config_t_cs_max,              //Address 'h08
    output logic [31:0]                     config_t_read_write_recovery, //Address 'h0C
    output logic [ADDR_MAPPING_WIDTH-1:0]   config_addr_mapping           //Address 'h10
);

    //Order of registers is inversed

    logic [ADDR_MAPPING_WIDTH-1:0] init_addr_mapping;

    for (genvar i = 0; i < NR_CS; i++) begin
        assign init_addr_mapping[2*i*32+31 : 2*i*32]    =  'h400000 * i;
        assign init_addr_mapping[2*i*32+63 : 2*i*32+32] = ('h400000 * i) + 'h3FFFFF;
    end

    reg_uniform #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 ),
        .NUM_REG    ( 4 + 2 * NR_CS ),
        .REG_WIDTH  ( 32 )
    ) registers (
        .clk_i      ( clk_i  ),
        .rst_ni     ( rst_ni ),
        .init_val_i ( {
                init_addr_mapping, //config_addr_mapping
                32'h6,             //config_t_read_write_recovery
                32'd666,           //config_t_cs_max
                32'h6,             //config_t_latency_additional
                32'h6              //config_t_latency_access
            } ),
        .rd_val_i   ( { config_addr_mapping, config_t_read_write_recovery, config_t_cs_max, config_t_latency_additional, config_t_latency_access } ),
        .wr_val_o   ( { config_addr_mapping, config_t_read_write_recovery, config_t_cs_max, config_t_latency_additional, config_t_latency_access } ),
        .wr_evt_o   (       ),
        .reg_i      ( cfg_i )
    );

endmodule
