`timescale 1ps/1ps

import axi_pkg::*;

module hyperbus_macro_inflate #(
    parameter BURST_WIDTH = 9,
    parameter NR_CS = 2,
    parameter AXI_AW = 32,
    parameter AXI_UW = 1,
    parameter AXI_IW = 10
)(
    input  logic                   clk_phy_i,
    input  logic                   clk_sys_i,
    input logic                    rst_ni,         // Asynchronous reset active low

    input [31:0]                   cfg_i_addr,
    input                          cfg_i_write,
    input [31:0]                   cfg_i_wdata,
    input [3:0]                    cfg_i_wstrb,
    input                          cfg_i_valid,
    output [31:0]                  cfg_i_rdata,
    output                         cfg_i_error,
    output                         cfg_i_ready,

    input  logic [AXI_IW-1:0]      axi_i_aw_id,
    input  logic [AXI_AW-1:0]      axi_i_aw_addr,
    input  logic [7:0]             axi_i_aw_len,
    input  logic [2:0]             axi_i_aw_size,
    input  burst_t                 axi_i_aw_burst,
    input  logic                   axi_i_aw_lock,
    input  cache_t                 axi_i_aw_cache,
    input  prot_t                  axi_i_aw_prot,
    input  qos_t                   axi_i_aw_qos,
    input  region_t                axi_i_aw_region,
    input  logic [AXI_UW-1:0]      axi_i_aw_user,
    input  logic                   axi_i_aw_valid,
    output logic                   axi_i_aw_ready,

    input  logic [15:0]            axi_i_w_data,
    input  logic [1:0]             axi_i_w_strb,
    input  logic                   axi_i_w_last,
    input  logic [AXI_UW-1:0]      axi_i_w_user,
    input  logic                   axi_i_w_valid,
    output logic                   axi_i_w_ready,

    output logic [AXI_IW-1:0]      axi_i_b_id,
    output resp_t                  axi_i_b_resp,
    output logic [AXI_UW-1:0]      axi_i_b_user,
    output logic                   axi_i_b_valid,
    input  logic                   axi_i_b_ready,

    input  logic [AXI_IW-1:0]      axi_i_ar_id,
    input  logic [AXI_AW-1:0]      axi_i_ar_addr,
    input  logic [7:0]             axi_i_ar_len,
    input  logic [2:0]             axi_i_ar_size,
    input  burst_t                 axi_i_ar_burst,
    input  logic                   axi_i_ar_lock,
    input  cache_t                 axi_i_ar_cache,
    input  prot_t                  axi_i_ar_prot,
    input  qos_t                   axi_i_ar_qos,
    input  region_t                axi_i_ar_region,
    input  logic [AXI_UW-1:0]      axi_i_ar_user,
    input  logic                   axi_i_ar_valid,
    output logic                   axi_i_ar_ready,

    output logic [AXI_IW-1:0]      axi_i_r_id,
    output logic [15:0]            axi_i_r_data,
    output resp_t                  axi_i_r_resp,
    output logic                   axi_i_r_last,
    output logic [AXI_UW-1:0]      axi_i_r_user,
    output logic                   axi_i_r_valid,
    input  logic                   axi_i_r_ready,

    // physical interface
    output logic                   hyper_reset_no,
    output logic [NR_CS-1:0]       hyper_cs_no,
    inout  wire                    hyper_ck_o,    //With Pad
    inout  wire                    hyper_ck_no,   //With Pad
    inout  wire                    hyper_rwds_io, //With Pad
    inout  wire [7:0]              hyper_dq_io    //With Pad
);

    assign cfg_i_rdata     = 'b0;              
    assign cfg_i_error     = 'b0;              
    assign cfg_i_ready     = 'b0;              
    assign axi_i_aw_ready  = 'b0;                 
    assign axi_i_w_ready   = 'b0;                
    assign axi_i_b_id      = 'b0;             
    assign axi_i_b_resp    = 'b0;               
    assign axi_i_b_user    = 'b0;               
    assign axi_i_b_valid   = 'b0;                
    assign axi_i_ar_ready  = 'b0;                 
    assign axi_i_r_id      = 'b0;             
    assign axi_i_r_data    = 'b0;                   
    assign axi_i_r_resp    = 'b0;               
    assign axi_i_r_last    = 'b0;               
    assign axi_i_r_user    = 'b0;               
    assign axi_i_r_valid   = 'b0;                

endmodule // hyperbus_macro_inflate