// Copyright (c) 2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
//
// Bug fixes and contributions will eventually be released under the
// SolderPad open hardware license in the context of the PULP platform
// (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
// University of Bologna.
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// An AXI4 to AXI4-Lite adapter.
///
/// Two internal FIFOs are used to perform ID reflection. The length of these
/// FIFOs determines the maximum number of outstanding transactions on the read
/// and write channels that the adapter can handle.
///
/// Burst accesses are not yet supported and DO NOT produce an error.
module axi_to_axi_lite #(
  /// Maximum number of outstanding reads.
  parameter int NUM_PENDING_RD = 1,
  /// Maximum number of outstanding writes.
  parameter int NUM_PENDING_WR = 1
)(
  input logic  clk_i,
  input logic  rst_ni,
  AXI_BUS.in   in,
  AXI_LITE.out out
);

  `ifndef SYNTHESIS
  initial begin
    assert(NUM_PENDING_RD > 0);
    assert(NUM_PENDING_WR > 0);
    assert(in.AXI_ADDR_WIDTH == out.AXI_ADDR_WIDTH);
    assert(in.AXI_DATA_WIDTH == out.AXI_DATA_WIDTH);
  end
  `endif

  // Round the maximum number of pending transactions up to the next power of
  // two. This is required by the implementation of the FIFO.
  localparam int DEPTH_FIFO_RD = 2**$clog2(NUM_PENDING_RD);
  localparam int DEPTH_FIFO_WR = 2**$clog2(NUM_PENDING_WR);

  // The transaction information that will be stored locally.
  typedef struct packed {
    logic [$bits(in.r_id)-1:0] id;
    logic [$bits(in.r_user)-1:0] user;
  } meta_rd_t;

  typedef struct packed {
    logic [$bits(in.b_id)-1:0] id;
    logic [$bits(in.b_user)-1:0] user;
  } meta_wr_t;

  // HACK: Rather than passing a meta_rd_t and meta_wr_t into the FIFO's data_o
  //       port, we destructure it into the constituent fields. If we don't do
  //       this, Synopsys DC 2016.03 throws an "Internal Error" on "meta_rd.id".
  logic [$bits(in.r_id)-1:0] meta_rd_id;
  logic [$bits(in.r_user)-1:0] meta_rd_user;
  logic [$bits(in.b_id)-1:0] meta_wr_id;
  logic [$bits(in.b_user)-1:0] meta_wr_user;

  // The two FIFOs which hold the transaction information.
  logic rd_full;
  logic wr_full;
  meta_rd_t meta_rd;
  meta_wr_t meta_wr;

  fifo #(.dtype(meta_rd_t), .DEPTH(DEPTH_FIFO_RD)) i_fifo_rd (
    .clk_i   ( clk_i                                        ),
    .rst_ni  ( rst_ni                                       ),
    .flush_i ( '0                                           ),
    .full_o  ( rd_full                                      ),
    .empty_o (                                              ),
    .threshold_o (                                          ),
    // For every transaction on the AR channel we push the ID and USER metadata
    // into the queue.
    .data_i  ( {in.ar_id, in.ar_user}                 ),
    .push_i  ( in.ar_ready & in.ar_valid              ),
    // After the last response on the R channel we pop the metadata off the
    // queue.
    .data_o  ( {meta_rd_id, meta_rd_user}                   ),
    .pop_i   ( in.r_valid & in.r_ready & in.r_last )
  );

  fifo #(.dtype(meta_wr_t), .DEPTH(DEPTH_FIFO_WR)) i_fifo_wr (
    .clk_i   ( clk_i                           ),
    .rst_ni  ( rst_ni                          ),
    .flush_i ( '0                              ),
    .full_o  ( wr_full                         ),
    .empty_o (                                 ),
    .threshold_o (                             ),
    // For every transaction on the AW channel we push the ID and USER metadata
    // into the queue.
    .data_i  ( {in.aw_id, in.aw_user}    ),
    .push_i  ( in.aw_ready & in.aw_valid ),
    // After the response on the B channel we pop the metadata off the queue.
    .data_o  ( {meta_wr_id, meta_wr_user}      ),
    .pop_i   ( in.b_valid & in.b_ready   )
  );

  // Accept transactions on the AW and AR channels if the corresponding FIFO is
  // not full.
  assign in.aw_ready  = ~wr_full & out.aw_ready;
  assign in.ar_ready  = ~rd_full & out.ar_ready;
  assign out.aw_addr  = in.aw_addr;
  assign out.ar_addr  = in.ar_addr;
  assign out.aw_valid = in.aw_valid;
  assign out.ar_valid = in.ar_valid;

  assign out.w_data  = in.w_data;
  assign out.w_strb  = in.w_strb;
  assign out.w_valid = in.w_valid;
  assign in.w_ready  = out.w_ready;

  // Inject the metadata again on the B and R return paths.
  assign in.b_id     = meta_wr_id;
  assign in.b_resp   = out.b_resp;
  assign in.b_user   = meta_wr_user;
  assign in.b_valid  = out.b_valid;
  assign out.b_ready = in.b_ready;

  assign in.r_id     = meta_rd_id;
  assign in.r_data   = out.r_data;
  assign in.r_resp   = out.r_resp;
  assign in.r_last   = '1;
  assign in.r_user   = meta_rd_user;
  assign in.r_valid  = out.r_valid;
  assign out.r_ready = in.r_ready;

endmodule