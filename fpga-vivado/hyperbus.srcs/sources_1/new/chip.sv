`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2018 03:33:46 PM
// Design Name: 
// Module Name: chip
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module chip #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2
)(
    input  logic                   clk_i,    // Clock
    input  logic                   rst_ni,   // Asynchronous reset active low


    // physical interface
    output logic [NR_CS-1:0]       hyper_cs_no,
    output logic                   hyper_ck_o,
    output logic                   hyper_ck_no,
    inout  logic                   hyper_rwds_io,
    inout  logic [7:0]             hyper_dq_io
);

    logic [31:0]            config_t_latency_access;
    logic [31:0]            config_t_latency_additional;
    logic [31:0]            config_t_cs_max;
    logic [31:0]            config_t_read_write_recovery;
    logic [31:0]            config_t_rwds_delay_line;

    // transactions
    logic                   trans_valid_i;
    logic                   trans_ready_o;
    logic [31:0]            trans_address_i;
    logic [NR_CS-1:0]       trans_cs_i;        // chipselect
    logic                   trans_write_i;     // transaction is a write
    logic [BURST_WIDTH-1:0] trans_burst_i;
    logic                   trans_address_space_i;
    logic                   trans_error;
    // transmitting
    logic                   tx_valid_i;
    logic                   tx_ready_o;
    logic [15:0]            tx_data_i;
    logic [1:0]             tx_strb_i;   // mask data
    // receiving channel
    logic                   rx_valid_o;
    logic                   rx_ready_i;
    logic [15:0]            rx_data_o;


    logic                   hyper_rwds_o;
    logic                   hyper_rwds_i;
    logic                   hyper_rwds_oe_o;
    logic [7:0]             hyper_dq_i;
    logic [7:0]             hyper_dq_o;
    logic                   hyper_dq_oe_o;


    hyperbus_phy #(.NR_CS(NR_CS), .BURST_WIDTH(BURST_WIDTH)) phy_i (
        .clk_i                        ( clk_i                        ),
        .rst_ni                       ( rst_ni                       ),
        .config_t_latency_access      ( config_t_latency_access      ),
        .config_t_latency_additional  ( config_t_latency_additional  ),
        .config_t_cs_max              ( config_t_cs_max              ),
        .config_t_read_write_recovery ( config_t_read_write_recovery ),
        .config_t_rwds_delay_line     ( config_t_rwds_delay_line     ),
        .trans_valid_i                ( trans_valid_i                ),
        .trans_ready_o                ( trans_ready_o                ),
        .trans_address_i              ( trans_address_i              ),
        .trans_cs_i                   ( trans_cs_i                   ),
        .trans_write_i                ( trans_write_i                ),
        .trans_burst_i                ( trans_burst_i                ),
        .trans_address_space_i        ( trans_address_space_i        ),
        .trans_error                  ( trans_error                  ),
        .tx_valid_i                   ( tx_valid_i                   ),
        .tx_ready_o                   ( tx_ready_o                   ),
        .tx_data_i                    ( tx_data_i                    ),
        .tx_strb_i                    ( tx_strb_i                    ),
        .rx_valid_o                   ( rx_valid_o                   ),
        .rx_ready_i                   ( rx_ready_i                   ),
        .rx_data_o                    ( rx_data_o                    ),
        .hyper_cs_no                  ( hyper_cs_no                  ),
        .hyper_ck_o                   ( hyper_ck_o                   ),
        .hyper_ck_no                  ( hyper_ck_no                  ),
        .hyper_rwds_o                 ( hyper_rwds_o                 ),
        .hyper_rwds_i                 ( hyper_rwds_i                 ),
        .hyper_rwds_oe_o              ( hyper_rwds_oe_o              ),
        .hyper_dq_i                   ( hyper_dq_i                   ),
        .hyper_dq_o                   ( hyper_dq_o                   ),
        .hyper_dq_oe_o                ( hyper_dq_oe_o                ),
        .hyper_reset_no               (                              )
    );

    pad_io pad_sim (
        .data_i   (hyper_rwds_o),   
        .oe_i     (hyper_rwds_oe_o),
        .data_o   (hyper_rwds_i),  
        .pad_io   (hyper_rwds_io) 
    );

    pad_io #(8) pad_sim_data (
        .data_i   (hyper_dq_o),   
        .oe_i     (hyper_dq_oe_o),
        .data_o   (hyper_dq_i),  
        .pad_io   (hyper_dq_io) 
    );


    assign config_t_latency_access = 32'h6;
    assign config_t_latency_additional = 32'h6;
    assign config_t_cs_max = 32'd666;
    assign config_t_read_write_recovery = 32'h6;
    assign config_t_rwds_delay_line = 32'd2000;
    assign trans_cs_i = 1'b01;
    assign trans_write_i = 1'b0;
    assign trans_address_space_i = 1'b0;
    assign tx_valid_i = 1'b0;
    assign tx_data_i = 1'h0;
    assign tx_strb_i = 1'b00;

    logic [0:0]  m_axi_awid;
    logic [31:0] m_axi_awaddr;
    logic [7:0]  m_axi_awlen;
    logic [2:0]  m_axi_awsize;
    logic [1:0]  m_axi_awburst;
    logic        m_axi_awlock;
    logic [3:0]  m_axi_awcache;
    logic [2:0]  m_axi_awprot;
    logic [3:0]  m_axi_awqos;
    logic        m_axi_awvalid;
    logic        m_axi_awready; //in

    logic [31:0] m_axi_wdata;
    logic [3:0]  m_axi_wstrb;
    logic        m_axi_wlast;
    logic        m_axi_wvalid;
    logic        m_axi_wready; //in

    logic [0:0]  m_axi_bid; //in
    logic [1:0]  m_axi_bresp; //in
    logic        m_axi_bvalid; //in
    logic        m_axi_bready;


    logic [0:0]  m_axi_arid;
    logic [31:0] m_axi_araddr;
    logic [7:0]  m_axi_arlen;
    logic [2:0]  m_axi_arsize;
    logic [1:0]  m_axi_arburst;
    logic        m_axi_arlock;
    logic [3:0]  m_axi_arcache;
    logic [2:0]  m_axi_arprot;
    logic [3:0]  m_axi_arqos;
    logic        m_axi_arvalid;
    logic        m_axi_arready; //in

    logic [0:0]  m_axi_rid; //in
    logic [31:0] m_axi_rdata; //in
    logic [1:0]  m_axi_rresp; //in
    logic        m_axi_rlast; //in
    logic        m_axi_rvalid; //in
    logic        m_axi_rready;

    assign m_axi_awready = 1'b0;
    assign m_axi_wready = 1'b0;
    assign m_axi_rresp = 2'h0;
    assign m_axi_bid = 1'b0;
    assign m_axi_bresp = 2'b0;
    assign m_axi_bvalid = 1'b0;

    assign m_axi_arready = trans_ready_o;
    assign trans_valid_i = m_axi_arvalid;
    assign trans_address_i = m_axi_araddr;
    assign trans_burst_i = m_axi_arburst;
    assign m_axi_rid = 1'b0;
    assign m_axi_rdata = rx_data_o;
    assign m_axi_rresp = 2'h0;
    assign m_axi_rlast = 1'b0;
    assign m_axi_rvalid = rx_valid_o;
    assign rx_ready_i = m_axi_rready;

    jtag_axi_0 jtag_axi_i (
        .aclk          ( clk_i         ),
        .aresetn       ( rst_ni        ),
        .m_axi_awid    ( m_axi_awid    ),
        .m_axi_awaddr  ( m_axi_awaddr  ),
        .m_axi_awlen   ( m_axi_awlen   ),
        .m_axi_awsize  ( m_axi_awsize  ),
        .m_axi_awburst ( m_axi_awburst ),
        .m_axi_awlock  ( m_axi_awlock  ),
        .m_axi_awcache ( m_axi_awcache ),
        .m_axi_awprot  ( m_axi_awprot  ),
        .m_axi_awqos   ( m_axi_awqos   ),
        .m_axi_awvalid ( m_axi_awvalid ),
        .m_axi_awready ( m_axi_awready ),
        .m_axi_wdata   ( m_axi_wdata   ),
        .m_axi_wstrb   ( m_axi_wstrb   ),
        .m_axi_wlast   ( m_axi_wlast   ),
        .m_axi_wvalid  ( m_axi_wvalid  ),
        .m_axi_wready  ( m_axi_wready  ),
        .m_axi_bid     ( m_axi_bid     ),
        .m_axi_bresp   ( m_axi_bresp   ),
        .m_axi_bvalid  ( m_axi_bvalid  ),
        .m_axi_bready  ( m_axi_bready  ),
        .m_axi_arid    ( m_axi_arid    ),
        .m_axi_araddr  ( m_axi_araddr  ),
        .m_axi_arlen   ( m_axi_arlen   ),
        .m_axi_arsize  ( m_axi_arsize  ),
        .m_axi_arburst ( m_axi_arburst ),
        .m_axi_arlock  ( m_axi_arlock  ),
        .m_axi_arcache ( m_axi_arcache ),
        .m_axi_arprot  ( m_axi_arprot  ),
        .m_axi_arqos   ( m_axi_arqos   ),
        .m_axi_arvalid ( m_axi_arvalid ),
        .m_axi_arready ( m_axi_arready ),
        .m_axi_rid     ( m_axi_rid     ),
        .m_axi_rdata   ( m_axi_rdata   ),
        .m_axi_rresp   ( m_axi_rresp   ),
        .m_axi_rlast   ( m_axi_rlast   ),
        .m_axi_rvalid  ( m_axi_rvalid  ),
        .m_axi_rready  ( m_axi_rready  ) 
    );

endmodule
