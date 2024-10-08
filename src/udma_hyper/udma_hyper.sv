// Copyright 2018-2021 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

//// Hayate Okuhara <hayate.okuhara@unibo.it>


module udma_hyperbus
  import hyperbus_pkg::*;

#(
    parameter L2_AWIDTH_NOAL  = 12,
    parameter TRANS_SIZE      = 16,
    parameter SYNC_STAGES     = 2,
    parameter DELAY_BIT_WIDTH = 3,
    parameter NumChips        =2,
    parameter NB_CH           =8,
    parameter int unsigned NumPhys       = -1,
    parameter type         hyper_tx_t    = logic,
    parameter type         hyper_rx_t    = logic,
    localparam BUFFER_DEPTH   =8
)
(
    input logic                        sys_clk_i,
    input logic                        clk_phy_i,
    input logic                        rst_ni,
    input logic                        phy_rst_ni,

    output logic [3:0]                 async_rx_wptr_o,
    input  logic [3:0]                 async_rx_rptr_i,
    output logic [31:0][7:0]           async_rx_data_o,

    input logic [3:0]                  async_tx_wptr_i,
    output logic [3:0]                 async_tx_rptr_o,
    input logic [31:0][7:0]            async_tx_data_i,

    input logic [31:0]                 cfg_data_i,
    input logic [4:0]                  cfg_addr_i,
    input logic [NB_CH:0]              cfg_valid_i,
    input logic                        cfg_rwn_i,
    output logic [NB_CH:0] [31:0]      cfg_data_o,
    output logic [NB_CH:0]             cfg_ready_o,

    output logic [L2_AWIDTH_NOAL-1:0]  udma_rx_startaddr_o,
    output logic [TRANS_SIZE-1:0]      udma_rx_size_o,
    output logic [1:0]                 cfg_rx_datasize_o,
    output logic                       cfg_rx_continuous_o,
    output logic                       udma_rx_en_o,
    output logic                       cfg_rx_clr_o,
    input logic                        cfg_rx_en_i,
    input logic                        cfg_rx_pending_i,
    input logic [L2_AWIDTH_NOAL-1:0]   cfg_rx_curr_addr_i,
    input logic [TRANS_SIZE-1:0]       cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0]  udma_tx_startaddr_o,
    output logic [TRANS_SIZE-1:0]      udma_tx_size_o,
    output logic [1:0]                 cfg_tx_datasize_o,
    output logic                       cfg_tx_continuous_o,
    output logic                       udma_tx_en_o,
    output logic                       cfg_tx_clr_o,
    input logic                        cfg_tx_en_i,
    input logic                        cfg_tx_pending_i,
    input logic [L2_AWIDTH_NOAL-1:0]   cfg_tx_curr_addr_i,
    input logic [TRANS_SIZE-1:0]       cfg_tx_bytes_left_i,
    output logic [NB_CH-1:0]           evt_eot_hyper_o,

    // configuration TODO : remove
    output logic [31:0]                config_t_latency_access,
    output logic [31:0]                config_en_latency_additional,
    output logic [31:0]                config_t_cs_max,
    output logic [31:0]                config_t_read_write_recovery,
    output logic [31:0]                config_t_variable_latency_check,
    output logic [DELAY_BIT_WIDTH-1:0] config_t_rwds_delay_line,

    // transactions
    output logic                       trans_valid_o,
    input logic                        trans_ready_i,
    output                             hyperbus_pkg::hyper_tf_t udma_phy_tf,
    output logic [NumChips-1:0]        trans_cs_o, // chipselect
    // transmitting
    output logic                       tx_valid_o,
    input logic                        tx_ready_i,
    output                             hyper_tx_t udma_phy_tx,
    // receiving channel
    input logic                        rx_valid_i,
    output logic                       rx_ready_o,
    input                              hyper_rx_t udma_phy_rx,
    // spram select
    output logic [1:0]                 mem_sel_o,
    output logic                       busy_o

);


   localparam LOG_NB_CH = (NB_CH == 1) ? 1 : $clog2(NB_CH);

   logic                          clk0;
   logic                          clk90;
// Signals for data communication (RX direction)
   logic                          rx_valid_phy;
   logic                          rx_ready_phy;
   logic [31:0]                   rx_data_phy;

   logic                          rx_valid_fifo;
   logic                          rx_ready_fifo;
   logic [31:0]                   rx_data_fifo;

// Singals for the transaction (PHY)

   logic                          phy_trans_valid;
   logic                          phy_trans_ready;
   logic [TRANS_SIZE-1:0]         trans_burst;
   logic [TRANS_SIZE-1:0]         remained_data;
   logic [NumChips-1:0]              trans_cs;

// Signals for data communication (TX direction)
   logic                          tx_valid_phy;
   logic                          tx_ready_phy;
   logic [31:0]                   tx_data_phy;

   logic [1:0]                    tx_data_upper_mask;
   logic [1:0]                    tx_data_lower_mask;
   logic                          tx_valid_fifo;
   logic                          tx_ready_fifo;
   logic [31:0]                   tx_data_fifo;

// Signals for Hyper bus configuration and communication settings

   logic [NB_CH:0] [31:0]         cfg_data;
   logic [NB_CH:0]                cfg_ready;


   logic [NB_CH-1:0][L2_AWIDTH_NOAL*2+TRANS_SIZE*6+32+16+1+1+1+1+1-1:0] trans_cmd_data;
   logic [NB_CH-1:0]              trans_cmd_valid;
   logic [NB_CH-1:0]              trans_cmd_ready;

// Signals for 2d-1d spliter
   logic                          twd_trans_valid;
   logic                          twd_trans_ready;
   logic [L2_AWIDTH_NOAL-1:0]     twd_rx_start_addr;
   logic [L2_AWIDTH_NOAL-1:0]     twd_tx_start_addr;
   logic [TRANS_SIZE-1:0]         twd_rx_size;
   logic [TRANS_SIZE-1:0]         twd_tx_size;
   logic [31:0]                   twd_hyper_addr;
   logic [15:0]                   twd_hyper_intreg;
   logic [2:0]                    twd_page_bound;
   logic                          twd_rw_hyper;
   logic                          twd_addr_space;
   logic                          twd_burst_type;
   logic [1:0]                    twd_mem_sel;
   logic [4:0]                    twd_chip_sel;
   logic                          twd_trans_ext_act;
   logic [TRANS_SIZE-1:0]         twd_trans_ext_count;
   logic [TRANS_SIZE-1:0]         twd_trans_ext_stride;
   logic                          twd_trans_l2_act;
   logic [TRANS_SIZE-1:0]         twd_trans_l2_count;
   logic [TRANS_SIZE-1:0]         twd_trans_l2_stride;

   logic [4:0]                    twd_t_latency_access;
   logic                          twd_en_latency_additional;
   logic [31:0]                   twd_t_cs_max;
   logic [31:0]                   twd_t_read_write_recovery;
   logic [DELAY_BIT_WIDTH-1:0]    twd_t_rwds_delay_line;
   logic [3:0]                    twd_t_variable_latency_check;


   logic [LOG_NB_CH-1:0]          twd_trans_id;

// Signals for 1d transactions
   logic                          ond_trans_valid;
   logic                          ond_trans_ready;
   logic [L2_AWIDTH_NOAL-1:0]     ond_rx_start_addr;
   logic [L2_AWIDTH_NOAL-1:0]     ond_tx_start_addr;
   logic [TRANS_SIZE-1:0]         ond_rx_size;
   logic [TRANS_SIZE-1:0]         ond_tx_size;
   logic [31:0]                   ond_hyper_addr;
   logic [15:0]                   ond_hyper_intreg;
   logic [2:0]                    ond_page_bound;
   logic                          ond_rw_hyper;
   logic                          ond_addr_space;
   logic                          ond_burst_type;
   logic [1:0]                    ond_mem_sel;
   logic [4:0]                    ond_chip_sel;
   logic [LOG_NB_CH:0]            ond_trans_id;

   logic [4:0]                    ond_t_latency_access;
   logic                          ond_en_latency_additional;
   logic [31:0]                   ond_t_cs_max;
   logic [31:0]                   ond_t_read_write_recovery;
   logic [DELAY_BIT_WIDTH-1:0]    ond_t_rwds_delay_line;
   logic [3:0]                    ond_t_variable_latency_check;


// Signals for the transaction stored in the FIFO
   logic [L2_AWIDTH_NOAL-1:0]     pack_rx_start_addr;
   logic [L2_AWIDTH_NOAL-1:0]     pack_tx_start_addr;
   logic [TRANS_SIZE-1:0]         pack_rx_size;
   logic [TRANS_SIZE-1:0]         pack_tx_size;
   logic [31:0]                   pack_hyper_addr;
   logic [15:0]                   pack_hyper_intreg;
   logic [2:0]                    pack_page_bound;
   logic                          pack_rw_hyper;
   logic                          pack_addr_space;
   logic                          pack_burst_type;
   logic                          pack_trans_valid;
   logic                          pack_trans_ready;
   logic [1:0]                    pack_mem_sel;
   logic [4:0]                    pack_chip_sel;
   logic [LOG_NB_CH:0]            pack_trans_id;

   logic [4:0]                    pack_t_latency_access;
   logic                          pack_en_latency_additional;
   logic [31:0]                   pack_t_cs_max;
   logic [31:0]                   pack_t_read_write_recovery;
   logic [DELAY_BIT_WIDTH-1:0]    pack_t_rwds_delay_line;
   logic [3:0]                    pack_t_variable_latency_check;


// unpack transaction
   logic [L2_AWIDTH_NOAL-1:0]     unpack_rx_start_addr;
   logic [L2_AWIDTH_NOAL-1:0]     unpack_tx_start_addr;
   logic [TRANS_SIZE-1:0]         unpack_rx_size;
   logic [TRANS_SIZE-1:0]         unpack_tx_size;
   logic [31:0]                   unpack_hyper_addr;
   logic [15:0]                   unpack_hyper_intreg;
   logic [1:0]                    unpack_rx_datasize;
   logic [1:0]                    unpack_tx_datasize;
   logic                          unpack_rw_hyper;
   logic                          unpack_addr_space;
   logic                          unpack_burst_type;
   logic                          unpack_trans_valid;
   logic                          unpack_trans_ready;
   logic [1:0]                    unpack_mem_sel;
   logic [4:0]                    unpack_chip_sel;
   logic [LOG_NB_CH:0]            unpack_trans_id;

   logic [4:0]                    unpack_t_latency_access;
   logic                          unpack_en_latency_additional;
   logic [31:0]                   unpack_t_cs_max;
   logic [31:0]                   unpack_t_read_write_recovery;
   logic [DELAY_BIT_WIDTH-1:0]    unpack_t_rwds_delay_line;
   logic [3:0]                    unpack_t_variable_latency_check;


// unpack transaction to udma

   logic [L2_AWIDTH_NOAL-1:0]     toudma_tx_start_addr;
   logic [TRANS_SIZE-1:0]         toudma_tx_size;

   logic [L2_AWIDTH_NOAL-1:0]     toudma_rx_start_addr;
   logic [TRANS_SIZE-1:0]         toudma_rx_size;
   logic                          toudma_trans_valid;
   logic                          toudma_rw_hyper;
   logic [LOG_NB_CH:0]            toudma_trans_id;

// Transactions buffered by the controller
   logic [TRANS_SIZE-1:0]         ctrl_rx_size;
   logic [TRANS_SIZE-1:0]         ctrl_tx_size;
   logic [31:0]                   ctrl_hyper_addr;
   logic [15:0]                   ctrl_hyper_intreg;
   logic [1:0]                    ctrl_mem_sel;
   logic [LOG_NB_CH:0]            ctrl_trans_id;
   logic                          ctrl_rw_hyper;
   logic                          ctrl_addr_space;
   logic                          ctrl_burst_type;
   logic                          ctrl_hyper_odd_saaddr;

   logic [4:0]                    ctrl_t_latency_access;
   logic                          ctrl_en_latency_additional;
   logic [31:0]                   ctrl_t_cs_max;
   logic [31:0]                   ctrl_t_read_write_recovery;
   logic [DELAY_BIT_WIDTH-1:0]    ctrl_t_rwds_delay_line;
   logic [3:0]                    ctrl_t_variable_latency_check;

// Lock signal
   logic [$clog2(BUFFER_DEPTH):0] nb_trans_waiting;
   logic [NB_CH-1:0] proc_id_vec_sys;
   logic [NB_CH-1:0] proc_id_vec_phy;
   logic running_trans_phy;
   logic running_trans_sys;
   logic [NB_CH-1:0] busy_vec;

   assign busy_o = |busy_vec;

   logic r_running_trans_phy;

   assign running_trans_phy = pack_trans_valid | (!pack_trans_ready) | unpack_trans_valid | (!unpack_trans_ready) | phy_trans_valid;

   assign clk0  =    clk_phy_i;

/////////////////////////////////////////////////////////////////////////
/////////////////////////Control Path////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

/////////////////////////Config register/////////////////////////////////
   genvar i;
   generate
     for(i=0; i<= NB_CH -1; i++)
       begin
         udma_cmd_queue #(
            .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
            .TRANS_SIZE(TRANS_SIZE),
            .MAX_NB_TRAN($clog2(BUFFER_DEPTH))
         ) u_cmd_if (
            .sys_clk_i                      ( sys_clk_i                    ),
            .phy_clk_i                      ( clk0                         ),
            .rst_ni                         ( rst_ni                       ),

            .cfg_data_i                     ( cfg_data_i                   ),
            .cfg_addr_i                     ( cfg_addr_i                   ),
            .cfg_valid_i                    ( cfg_valid_i[i]               ),
            .cfg_reg_rwn_i                  ( cfg_rwn_i                    ),
            .cfg_ready_o                    ( cfg_ready_o[i]               ),
            .cfg_data_o                     ( cfg_data_o[i]                ),

            .running_trans_phy_i            ( running_trans_phy            ),
            .proc_id_sys_i                  ( proc_id_vec_sys[i]           ),
            .proc_id_phy_i                  ( proc_id_vec_phy[i]           ),

            .trans_cmd_data_o               ( trans_cmd_data[i]            ),
            .trans_cmd_ready_i              ( trans_cmd_ready[i]           ),
            .trans_cmd_valid_o              ( trans_cmd_valid[i]           ),
            .evt_eot_o                      ( evt_eot_hyper_o[i]           ),
            .busy_o                         ( busy_vec[i]                  )
       );
       end
   endgenerate

   rr_arb_tree #(
      .DataWidth(L2_AWIDTH_NOAL*2+TRANS_SIZE*6+32+16+1+1+1+1+1),
      .NumIn(NB_CH)
   ) arbiter_i (
       .clk_i              ( sys_clk_i                                       ),
       .rst_ni             ( rst_ni                                          ),
       .flush_i            ( 1'b0                                            ),
       .rr_i               ( '0                                              ),
       .req_i              ( trans_cmd_valid                                 ),
       .gnt_o              ( trans_cmd_ready                                 ),
       .data_i             ( trans_cmd_data                                  ),

       .idx_o              ( twd_trans_id                                    ),
       .req_o              ( twd_trans_valid                                 ),
       .gnt_i              ( twd_trans_ready                                 ),
       .data_o             ({twd_rx_start_addr,   twd_rx_size,
                             twd_tx_start_addr,   twd_tx_size,
                             twd_hyper_addr,      twd_hyper_intreg,
                             twd_rw_hyper,        twd_addr_space,
                             twd_burst_type,      twd_trans_ext_act,
                             twd_trans_ext_count, twd_trans_ext_stride,
                             twd_trans_l2_act,    twd_trans_l2_count,
                             twd_trans_l2_stride}  )
   );

   udma_hyper_reg_if_common #(
      .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
      .TRANS_SIZE(TRANS_SIZE),
      .DELAY_BIT_WIDTH(DELAY_BIT_WIDTH),
      .NB_CH(NB_CH),
      .MAX_NB_TRAN($clog2(BUFFER_DEPTH))
   ) u_reg_if (
      .clk_i                          ( sys_clk_i                    ),
      .rst_ni                         ( rst_ni                       ),

      .cfg_data_i                     ( cfg_data_i                   ),
      .cfg_addr_i                     ( cfg_addr_i                   ),
      .cfg_valid_i                    ( cfg_valid_i[NB_CH]           ),
      .cfg_reg_rwn_i                  ( cfg_rwn_i                    ),
      .cfg_ready_o                    ( cfg_ready_o[NB_CH]           ),
      .cfg_data_o                     ( cfg_data_o[NB_CH]            ),

      .cfg_t_latency_access_o         ( twd_t_latency_access         ),
      .cfg_en_latency_additional_o    ( twd_en_latency_additional    ),
      .cfg_t_cs_max_o                 ( twd_t_cs_max                 ),
      .cfg_t_read_write_recovery_o    ( twd_t_read_write_recovery    ),
      .cfg_t_rwds_delay_line_o        ( twd_t_rwds_delay_line        ),
      .cfg_t_variable_latency_check_o ( twd_t_variable_latency_check ),
      .cfg_chipsel_sel_o              ( twd_chip_sel                 ),
      .cfg_page_bound_o               ( twd_page_bound               ),
      .cfg_mem_sel_o                  ( twd_mem_sel                  ),
      .busy_vec_i                     ( busy_vec                     )

   );

   /////////////////////////////////////////////
   assign cfg_tx_datasize_o = 2'b10;
   assign cfg_rx_datasize_o = 2'b10;
   assign cfg_rx_continuous_o = 1'b0;
   assign cfg_tx_continuous_o = 1'b0;
   assign cfg_rx_clr_o = 1'b0;
   assign cfg_tx_clr_o = 1'b0;


   hyper_twd_trans_spliter  #(
      .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
      .ID_WIDTH(LOG_NB_CH),
      .DELAY_BIT_WIDTH(DELAY_BIT_WIDTH),
      .TRANS_SIZE(TRANS_SIZE)
   ) hyper_twd_trans_spliter_i
   (
      .clk_i                  ( sys_clk_i             ),
      .rst_ni                 ( rst_ni                ),

      .src_valid_i            ( twd_trans_valid       ),
      .src_ready_o            ( twd_trans_ready       ),

      .dst_ready_i            ( ond_trans_ready       ),
      .dst_valid_o            ( ond_trans_valid       ),

      .rx_start_addr_i        ( twd_rx_start_addr     ),
      .tx_start_addr_i        ( twd_tx_start_addr     ),
      .rx_size_i              ( twd_rx_size           ),
      .tx_size_i              ( twd_tx_size           ),

      .hyper_sa_addr_i        ( twd_hyper_addr        ),
      .hyper_int_reg_i        ( twd_hyper_intreg      ),
      .hyper_page_bound_i     ( twd_page_bound        ),
      .rw_hyper_i             ( twd_rw_hyper          ),
      .addr_space_i           ( twd_addr_space        ),
      .burst_type_i           ( twd_burst_type        ),
      .mem_sel_i              ( twd_mem_sel           ),
      .chip_sel_i             ( twd_chip_sel          ),
      .trans_id_i             ( twd_trans_id          ),

      .twd_trans_ext_act_i    ( twd_trans_ext_act     ),
      .twd_trans_ext_count_i  ( twd_trans_ext_count   ),
      .twd_trans_ext_stride_i ( twd_trans_ext_stride  ),
      .twd_trans_l2_act_i     ( twd_trans_l2_act      ),
      .twd_trans_l2_count_i   ( twd_trans_l2_count    ),
      .twd_trans_l2_stride_i  ( twd_trans_l2_stride   ),

      .cfg_t_latency_access_i         ( twd_t_latency_access         ),
      .cfg_en_latency_additional_i    ( twd_en_latency_additional    ),
      .cfg_t_cs_max_i                 ( twd_t_cs_max                 ),
      .cfg_t_read_write_recovery_i    ( twd_t_read_write_recovery    ),
      .cfg_t_rwds_delay_line_i        ( twd_t_rwds_delay_line        ),
      .cfg_t_variable_latency_check_i ( twd_t_variable_latency_check ),

      .rx_start_addr_o        ( ond_rx_start_addr     ),
      .tx_start_addr_o        ( ond_tx_start_addr     ),
      .rx_size_o              ( ond_rx_size           ),
      .tx_size_o              ( ond_tx_size           ),
      .hyper_sa_addr_o        ( ond_hyper_addr        ),
      .hyper_int_reg_o        ( ond_hyper_intreg      ),
      .hyper_page_bound_o     ( ond_page_bound        ),
      .rw_hyper_o             ( ond_rw_hyper          ),
      .addr_space_o           ( ond_addr_space        ),
      .burst_type_o           ( ond_burst_type        ),
      .mem_sel_o              ( ond_mem_sel           ),
      .chip_sel_o             ( ond_chip_sel          ),
      .trans_id_o             ( ond_trans_id          ),

      .t_latency_access_o         ( ond_t_latency_access         ),
      .en_latency_additional_o    ( ond_en_latency_additional    ),
      .t_cs_max_o                 ( ond_t_cs_max                 ),
      .t_read_write_recovery_o    ( ond_t_read_write_recovery    ),
      .t_rwds_delay_line_o        ( ond_t_rwds_delay_line        ),
      .t_variable_latency_check_o ( ond_t_variable_latency_check )

   );

/////////////////////////Transaction FIFO/////////////////////////////////
// The data width here is the sum of the width of the transaction elements.

   udma_dc_fifo #(
      .DATA_WIDTH(L2_AWIDTH_NOAL*2+TRANS_SIZE*2+32*3+16+5+3+DELAY_BIT_WIDTH+4+2+1*5+LOG_NB_CH+5),
      .BUFFER_DEPTH(BUFFER_DEPTH)
     ) u_dc_tran
     (
      .dst_clk_i          ( clk0                                   ),
      .dst_rstn_i         ( phy_rst_ni                             ),

      .dst_data_o         ( {pack_rx_start_addr,     pack_rx_size,
                             pack_tx_start_addr,     pack_tx_size,
                             pack_hyper_addr,        pack_hyper_intreg,
                             pack_page_bound,        pack_rw_hyper,
                             pack_addr_space,        pack_burst_type,
                             pack_mem_sel,           pack_chip_sel,
                             pack_trans_id,
                             pack_t_latency_access,  pack_en_latency_additional,
                             pack_t_cs_max,          pack_t_read_write_recovery,
                             pack_t_rwds_delay_line, pack_t_variable_latency_check}
                           ),
      .dst_valid_o        ( pack_trans_valid                        ),
      .dst_ready_i        ( pack_trans_ready                        ),

      .src_clk_i          ( sys_clk_i                               ),
      .src_rstn_i         ( rst_ni                                  ),

      .src_data_i         ( {ond_rx_start_addr,     ond_rx_size,
                             ond_tx_start_addr,     ond_tx_size,
                             ond_hyper_addr,        ond_hyper_intreg,
                             ond_page_bound,        ond_rw_hyper,
                             ond_addr_space,        ond_burst_type,
                             ond_mem_sel,           ond_chip_sel,
                             ond_trans_id,
                             ond_t_latency_access,  ond_en_latency_additional,
                             ond_t_cs_max,          ond_t_read_write_recovery,
                             ond_t_rwds_delay_line, ond_t_variable_latency_check}
                          ),
      .src_valid_i        ( ond_trans_valid                         ),
      .src_ready_o        ( ond_trans_ready                         )
      );

   udma_dc_fifo #(
       .DATA_WIDTH(L2_AWIDTH_NOAL*2+TRANS_SIZE*2+1+LOG_NB_CH+1),
       .BUFFER_DEPTH(4)
     ) u_dc_toduma (
      .dst_clk_i          ( sys_clk_i                               ),
      .dst_rstn_i         ( rst_ni                                  ),

      .dst_data_o         ( {toudma_tx_start_addr, toudma_tx_size,
                             toudma_rw_hyper, toudma_rx_start_addr,
                             toudma_rx_size, toudma_trans_id}       ),
      .dst_valid_o        ( toudma_trans_valid                      ),
      .dst_ready_i        ( 1'b1                                    ),

      .src_clk_i          ( clk0                                    ),
      .src_rstn_i         ( phy_rst_ni                              ),

      .src_data_i         ( {unpack_tx_start_addr, unpack_tx_size,
                             unpack_rw_hyper, unpack_rx_start_addr,
                             unpack_rx_size, unpack_trans_id}       ),
      .src_valid_i        ( unpack_trans_valid & unpack_trans_ready ),
      .src_ready_o        (                                         )
     );

  udma_cfg_outbuff #(
       .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
       .ID_WIDTH(LOG_NB_CH),
       .NB_CH(NB_CH),
       .TRANS_SIZE(TRANS_SIZE)
    ) udma_cfg_outbuff_i (
      .clk_i                   ( sys_clk_i            ),
      .rst_ni                  ( rst_ni               ),

      .toudma_tx_start_addr_i  ( toudma_tx_start_addr ),
      .toudma_tx_size_i        ( toudma_tx_size       ),

      .toudma_rx_start_addr_i  ( toudma_rx_start_addr ),
      .toudma_rx_size_i        ( toudma_rx_size       ),

      .toudma_rw_hyper_i       ( toudma_rw_hyper      ),
      .toudma_trans_valid_i    ( toudma_trans_valid   ),
      .toudma_trans_id_i       ( toudma_trans_id      ),

      .udma_tx_start_addr_o    ( udma_tx_startaddr_o  ),
      .udma_tx_size_o          ( udma_tx_size_o       ),
      .udma_tx_en_o            ( udma_tx_en_o         ),
      .udma_rx_start_addr_o    ( udma_rx_startaddr_o  ),
      .udma_rx_size_o          ( udma_rx_size_o       ),
      .udma_rx_en_o            ( udma_rx_en_o         ),

      .udma_tx_en_i            ( cfg_tx_en_i          ),
      .udma_rx_en_i            ( cfg_rx_en_i          ),

      .rx_bytes_left_i         ( cfg_rx_bytes_left_i  ),
      .tx_bytes_left_i         ( cfg_tx_bytes_left_i  ),
      .proc_id_vec_sys_o       ( proc_id_vec_sys      )
    );

   hyper_unpack #(
      .L2_AWIDTH_NOAL          ( L2_AWIDTH_NOAL       ),
      .TRANS_SIZE              ( TRANS_SIZE           ),
      .DELAY_BIT_WIDTH         ( DELAY_BIT_WIDTH      ),
      .ID_WIDTH                ( LOG_NB_CH            ),
      .NR_CS                   ( NumChips             )
   ) hyper_unpack_i(
      .clk_i                   ( clk0                 ),
      .rst_ni                  ( phy_rst_ni           ),

      .pack_trans_valid_i      ( pack_trans_valid     ),
      .pack_trans_ready_o      ( pack_trans_ready     ),
      .pack_rx_size_i          ( pack_rx_size         ),
      .pack_tx_size_i          ( pack_tx_size         ),
      .pack_rx_start_addr_i    ( pack_rx_start_addr   ),
      .pack_tx_start_addr_i    ( pack_tx_start_addr   ),
      .pack_rw_hyper_i         ( pack_rw_hyper        ),
      .pack_addr_space_i       ( pack_addr_space      ),
      .pack_burst_type_i       ( pack_burst_type      ),
      .pack_page_bound_i       ( pack_page_bound      ),
      .pack_hyper_addr_i       ( pack_hyper_addr      ),
      .pack_hyper_intreg_i     ( pack_hyper_intreg    ),
      .pack_mem_sel_i          ( pack_mem_sel         ),
      .pack_chip_sel_i         ( pack_chip_sel        ),
      .pack_trans_id_i         ( pack_trans_id        ),

      .pack_t_latency_access_i         ( pack_t_latency_access         ),
      .pack_en_latency_additional_i    ( pack_en_latency_additional    ),
      .pack_t_cs_max_i                 ( pack_t_cs_max                 ),
      .pack_t_read_write_recovery_i    ( pack_t_read_write_recovery    ),
      .pack_t_rwds_delay_line_i        ( pack_t_rwds_delay_line        ),
      .pack_t_variable_latency_check_i ( pack_t_variable_latency_check ),

      .unpack_trans_ready_i    ( unpack_trans_ready   ),
      .unpack_trans_valid_o    ( unpack_trans_valid   ),
      .unpack_hyper_addr_o     ( unpack_hyper_addr    ),
      .unpack_hyper_intreg_o   ( unpack_hyper_intreg  ),
      .unpack_rx_start_addr_o  ( unpack_rx_start_addr ),
      .unpack_tx_start_addr_o  ( unpack_tx_start_addr ),
      .unpack_rx_size_o        ( unpack_rx_size       ),
      .unpack_tx_size_o        ( unpack_tx_size       ),
      .unpack_rw_hyper_o       ( unpack_rw_hyper      ),
      .unpack_addr_space_o     ( unpack_addr_space    ),
      .unpack_burst_type_o     ( unpack_burst_type    ),
      .unpack_mem_sel_o        ( unpack_mem_sel       ),
      .unpack_chip_sel_o       ( unpack_chip_sel      ),
      .unpack_trans_id_o       ( unpack_trans_id      ),
      .unpack_rx_en_o          ( unpack_rx_en         ),
      .unpack_tx_en_o          ( unpack_tx_en         ),

      .unpack_t_latency_access_o         ( unpack_t_latency_access         ),
      .unpack_en_latency_additional_o    ( unpack_en_latency_additional    ),
      .unpack_t_cs_max_o                 ( unpack_t_cs_max                 ),
      .unpack_t_read_write_recovery_o    ( unpack_t_read_write_recovery    ),
      .unpack_t_rwds_delay_line_o        ( unpack_t_rwds_delay_line        ),
      .unpack_t_variable_latency_check_o ( unpack_t_variable_latency_check )
   );

//////////////////Controller/////////////////////////////////

   udma_hyper_ctrl #(
      .L2_AWIDTH_NOAL              ( L2_AWIDTH_NOAL            ),
      .TRANS_SIZE                  ( TRANS_SIZE                ),
      .DELAY_BIT_WIDTH             ( DELAY_BIT_WIDTH           ),
      .ID_WIDTH                    ( LOG_NB_CH                 ),
      .NR_CS                       ( NumChips                  ),
      .NumPhys                     ( NumPhys                   )
   )udma_hyper_ctrl_i
   (
      .clk_i                       ( clk0                      ),
      .rst_ni                      ( phy_rst_ni                ),
      .unpack_trans_ready_o        ( unpack_trans_ready        ),
      .unpack_trans_valid_i        ( unpack_trans_valid        ),
      .phy_trans_valid_o           ( phy_trans_valid           ),
      .phy_trans_ready_i           ( phy_trans_ready           ),

      .rx_size_i                   ( unpack_rx_size            ),
      .tx_size_i                   ( unpack_tx_size            ),
      .rw_hyper_i                  ( unpack_rw_hyper           ),
      .addr_space_i                ( unpack_addr_space         ),
      .rx_ready_phy_i              ( rx_ready_phy              ),
      .rx_valid_phy_i              ( rx_valid_phy              ),
      .tx_valid_phy_i              ( tx_valid_phy              ),
      .tx_ready_phy_i              ( tx_ready_phy              ),
      .burst_type_i                ( unpack_burst_type         ),

      .unpack_t_latency_access_i         ( unpack_t_latency_access         ),
      .unpack_en_latency_additional_i    ( unpack_en_latency_additional    ),
      .unpack_t_cs_max_i                 ( unpack_t_cs_max                 ),
      .unpack_t_read_write_recovery_i    ( unpack_t_read_write_recovery    ),
      .unpack_t_rwds_delay_line_i        ( unpack_t_rwds_delay_line        ),
      .unpack_t_variable_latency_check_i ( unpack_t_variable_latency_check ),

      .hyper_addr_i                ( unpack_hyper_addr         ),
      .hyper_intreg_i              ( unpack_hyper_intreg       ),
      .remained_data_o             ( remained_data             ),
      .mem_sel_i                   ( unpack_mem_sel            ),
      .chip_sel_i                  ( unpack_chip_sel           ),
      .trans_id_i                  ( unpack_trans_id           ),

      .ctrl_rx_size_o              ( ctrl_rx_size              ),
      .ctrl_tx_size_o              ( ctrl_tx_size              ),
      .ctrl_rw_hyper_o             ( ctrl_rw_hyper             ),
      .ctrl_addr_space_o           ( ctrl_addr_space           ),
      .ctrl_hyper_addr_o           ( ctrl_hyper_addr           ),
      .ctrl_hyper_intreg_o         ( ctrl_hyper_intreg         ),
      .ctrl_burst_type_o           ( ctrl_burst_type           ),
      .ctrl_mem_sel_o              ( ctrl_mem_sel              ),
      .ctrl_trans_id_o             ( ctrl_trans_id             ),

      .data_mask_lower_o           ( tx_data_lower_mask        ),
      .data_mask_upper_o           ( tx_data_upper_mask        ),
      .hyper_odd_saaddr_o          ( ctrl_hyper_odd_saaddr     ),
      .trans_cs_o                  ( trans_cs                  ),
      .trans_burst_o               ( trans_burst               ),

      .ctrl_t_latency_access_o         ( ctrl_t_latency_access         ),
      .ctrl_en_latency_additional_o    ( ctrl_en_latency_additional    ),
      .ctrl_t_cs_max_o                 ( ctrl_t_cs_max                 ),
      .ctrl_t_read_write_recovery_o    ( ctrl_t_read_write_recovery    ),
      .ctrl_t_rwds_delay_line_o        ( ctrl_t_rwds_delay_line        ),
      .ctrl_t_variable_latency_check_o ( ctrl_t_variable_latency_check )
  );

  udma_hyper_busy_phy #(
     .ID_WIDTH(LOG_NB_CH),
     .NB_CH(NB_CH)
  ) udma_hyper_busy_phy_i (
    .clk_i                ( clk0            ),
    .rst_ni               ( phy_rst_ni      ),
    .unpack_trans_id_i    ( unpack_trans_id ),
    .ctrl_trans_id_i      ( ctrl_trans_id   ),
    .proc_id_vec_o        ( proc_id_vec_phy )
  );

/////////////////////////////////////////////////////////////////////////
/////////////////////////Data Path///////////////////////////////////////
/////////////////////////////////////////////////////////////////////////


///////////////READ PATH///////////////////////////////////////////
   udma_rxbuffer #(
      .TRANS_SIZE(TRANS_SIZE)
   )udma_rx_buffer_i(
      .clk_i              ( clk0                  ),
      .rst_ni             ( phy_rst_ni            ),
      .cfg_addr_space_i   ( ctrl_addr_space       ),
      .cfg_rx_size_i      ( ctrl_rx_size          ),
      .hyper_odd_saaddr_i ( ctrl_hyper_odd_saaddr ),
      .remained_data_i    ( remained_data         ),
      .mem_sel_i          ( ctrl_mem_sel          ),
      .src_valid_i        ( rx_valid_phy          ),
      .src_ready_o        ( rx_ready_phy          ),
      .dst_ready_i        ( rx_ready_fifo         ),
      .dst_valid_o        ( rx_valid_fifo         ),
      .data_i             ( rx_data_phy           ),
      .data_o             ( rx_data_fifo          )
   );

   cdc_fifo_gray_src #(
    .T(logic[31:0]),
    .LOG_DEPTH(3),
    .SYNC_STAGES(SYNC_STAGES)
    ) u_dc_rx (
      .src_clk_i          ( clk0                 ),
      .src_rst_ni         ( phy_rst_ni           ),
      .src_data_i         ( rx_data_fifo         ),
      .src_valid_i        ( rx_valid_fifo        ),
      .src_ready_o        ( rx_ready_fifo        ),
      .async_data_o       ( async_rx_data_o      ),
      .async_wptr_o       ( async_rx_wptr_o      ),
      .async_rptr_i       ( async_rx_rptr_i      )
      );

///////////////////WIRTE PATH////////////////////////////////////

   udma_txbuffer #(
      .TRANS_SIZE         ( TRANS_SIZE            )
   )udma_tx_buffer_i
     (
      .clk_i              ( clk0                  ),
      .rst_ni             ( phy_rst_ni            ),

      .mem_sel_i          ( ctrl_mem_sel          ),
      .burst_type_i       ( ctrl_burst_type       ),
      .cfg_addr_space_i   ( ctrl_addr_space       ),
      .cfg_hyper_intreg_i ( ctrl_hyper_intreg     ),

      .trans_handshake_i  ( trans_ready_i && phy_trans_valid ),

      .remained_data_i    ( remained_data         ),
      .src_valid_i        ( tx_valid_fifo         ),
      .src_ready_o        ( tx_ready_fifo         ),
      .data_i             ( tx_data_fifo          ),
      .hyper_odd_saaddr_i ( ctrl_hyper_odd_saaddr ),

      .dst_ready_i        ( tx_ready_phy          ),
      .dst_valid_o        ( tx_valid_phy          ),
      .data_o             ( tx_data_phy           )
     );

    cdc_fifo_gray_dst   #(
         .T(logic[31:0]),
         .LOG_DEPTH(3),
         .SYNC_STAGES(SYNC_STAGES)
         ) u_dc_tx (
           .async_data_i (async_tx_data_i),
           .async_wptr_i (async_tx_wptr_i),
           .async_rptr_o (async_tx_rptr_o),
           .dst_rst_ni   (phy_rst_ni),
           .dst_clk_i    (clk0),
           .dst_data_o   (tx_data_fifo),
           .dst_valid_o  (tx_valid_fifo),
           .dst_ready_i  (tx_ready_fifo)
      );

   assign config_t_latency_access         ={ 27'b0, ctrl_t_latency_access };
   assign config_en_latency_additional    ={ 31'b0, ctrl_en_latency_additional };
   assign config_t_cs_max                 =ctrl_t_cs_max;
   assign config_t_read_write_recovery    =ctrl_t_read_write_recovery;
   assign config_t_rwds_delay_line        =ctrl_t_rwds_delay_line;
   assign config_t_variable_latency_check ={ 28'b0, ctrl_t_variable_latency_check };

   assign trans_valid_o                   =phy_trans_valid;
   assign phy_trans_ready                 =trans_ready_i;
   assign trans_cs_o                      =trans_cs;
   assign udma_phy_tf.address             =ctrl_hyper_addr;
   assign udma_phy_tf.write               =~ctrl_rw_hyper;
   assign udma_phy_tf.burst               =trans_burst;
   assign udma_phy_tf.burst_type          =ctrl_burst_type;
   assign udma_phy_tf.address_space       =ctrl_addr_space;

   assign tx_valid_o                      =tx_valid_phy;
   assign tx_ready_phy                    =tx_ready_i;
   assign udma_phy_tx.data                =tx_data_phy[(NumPhys*16)-1:0];

   if(NumPhys==1) begin
     assign udma_phy_tx.strb              =~tx_data_lower_mask;
     assign rx_data_phy                   ={16'h0,udma_phy_rx.data};
   end else begin
     assign udma_phy_tx.strb              ={~tx_data_upper_mask,~tx_data_lower_mask};
     assign rx_data_phy                   =udma_phy_rx.data;
   end

   assign udma_phy_tx.last                =((remained_data==NumPhys)||(remained_data==1))&tx_valid_phy&tx_ready_phy;

   assign rx_valid_phy                    =rx_valid_i;
   assign rx_ready_o                      =rx_ready_phy;
   assign mem_sel_o                       =ctrl_mem_sel;

    // =========================
    //    Assertions
    // =========================

    // pragma translate_off
    `ifndef VERILATOR
    initial assert (NumChips <=5)
            else $error("NumChips > 5 is not supported");
    `endif
    // pragma translate_on

endmodule // udma_hyperbus_mulid
