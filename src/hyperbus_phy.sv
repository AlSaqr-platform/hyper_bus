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
// Description: Connect the AXI interface with the actual HyperBus
`timescale 1 ps/1 ps

module hyperbus_phy #(
    parameter BURST_WIDTH = 12,
    parameter NR_CS = 2,
    parameter WAIT_CYCLES = 6
)(
    input logic                    clk_i,    // Clock
    input logic                    rst_ni,   // Asynchronous reset active low
    // transactions
    input  logic                   trans_valid_i,
    output logic                   trans_ready_o,
    input  logic [31:0]            trans_address_i,
    input  logic [NR_CS-1:0]       trans_cs_i,        // chipselect
    input  logic                   trans_write_i,     // transaction is a write
    input  logic [BURST_WIDTH-1:0] trans_burst_i,
    input  logic                   trans_address_space_i,
    // transmitting
    input  logic                   tx_valid_i,
    output logic                   tx_ready_o,
    input  logic [15:0]            tx_data_i,
    input  logic [1:0]             tx_strb_i,   // mask data
    // receiving channel
    output logic                   rx_valid_o,
    input  logic                   rx_ready_i,
    output logic [15:0]            rx_data_o,
    // physical interface
    output logic [NR_CS-1:0]       hyper_cs_no,
    output logic                   hyper_ck_o,
    output logic                   hyper_ck_no,
    output logic                   hyper_rwds_o,
    input  logic                   hyper_rwds_i,
    output logic                   hyper_rwds_oe_o,
    input  logic [7:0]             hyper_dq_i,
    output logic [7:0]             hyper_dq_o,
    output logic                   hyper_dq_oe_o,
    output logic                   hyper_reset_no
);

    logic [47:0] cmd_addr;
    logic [15:0] data_out;
    logic [1:0]  data_rwds_out;
    logic [15:0] CA_out;
    logic [1:0]  cmd_addr_sel;
    logic [15:0] write_data;
    logic [1:0]  write_strb;

    //local copy of transaction
    logic [31:0]            local_address;
    logic [NR_CS-1:0]       local_cs;
    logic                   local_write;
    logic [BURST_WIDTH-1:0] local_burst;
    logic                   local_address_space;

    logic clock_enable;
    logic en_cs;
    logic en_ddr_in;
    logic request_wait_read;
    logic request_wait_write;
    logic en_read_transaction;
    logic en_write;
    logic [15:0] data_i;
    logic hyper_rwds_i_d;

    logic clk0;
    logic clk90;
    logic clk180;
    logic clk270;
    logic address_space;
    logic data_i_valid;

    typedef enum logic[3:0] {STANDBY,SET_CMD_ADDR, CMD_ADDR, REG_WRITE, WAIT2, WAIT, DATA_W, DATA_R, WAIT_R, WAIT_W, START_DATA_W, END} hyper_trans_t;

    hyper_trans_t hyper_trans_state;

    clk_gen ddr_clk (
        .clk_i    ( clk_i  ),
        .rst_ni   ( rst_ni ),
        .clk0_o   ( clk0   ),
        .clk90_o  ( clk90  ),
        .clk180_o ( clk180 ),
        .clk270_o ( clk270 )
    );

    pulp_clock_gating hyper_ck_gating (
        .clk_i      ( clk90                         ),
        .en_i       ( clock_enable && ~request_wait_read ),
        .test_en_i  ( 1'b0         ),
        .clk_o      ( hyper_ck_o   )
    ); 

    pulp_clock_inverter hyper_ck_no_inv (
        .clk_i ( hyper_ck_o  ),
        .clk_o ( hyper_ck_no )
    );

    assign hyper_reset_no = 1;

    //selecting ram must be in sync with future hyper_ck_o
    always_ff @(posedge clk270 or negedge rst_ni) begin : proc_hyper_cs_no
        if(~rst_ni) begin
            hyper_cs_no <= {NR_CS{1'b1}};
        end else begin
            hyper_cs_no[0] <= ~ (en_cs && local_cs[0]);
            hyper_cs_no[1] <= ~ (en_cs && local_cs[1]); //ToDo Use NR_CS
        end
    end

    assign #2000 hyper_rwds_i_d = hyper_rwds_i; //Delay of rwds for center aligned read
    
    genvar i;
    generate
      for(i=0; i<=7; i++)
      begin: ddr_out_bus
        ddr_out ddr_data (
          .rst_ni (rst_ni),
          .clk_i (clk0),
          .d0_i (data_out[i+8]),
          .d1_i (data_out[i]),
          .q_o (hyper_dq_o[i])
        );
      end
    endgenerate

    assign data_out = en_write ? write_data : CA_out;
    assign data_rwds_out = en_write ? write_strb : 2'b00; //RWDS low before end of initial latency

    ddr_out ddr_data_strb (
      .rst_ni (rst_ni),
      .clk_i (clk0),
      .d0_i (data_rwds_out[1]),
      .d1_i (data_rwds_out[0]),
      .q_o (hyper_rwds_o)
    );

    cmd_addr_gen cmd_addr_gen (
        .rw_i            ( ~local_write     	),
        .address_space_i ( local_address_space 	),
        .burst_type_i    ( 1'b1             	),
        .address_i       ( local_address    	),
        .cmd_addr_o      ( cmd_addr         	)
    );

    ddr_in ddr_in (
        .clk0            ( clk0           ),
        .hyper_rwds_i_d  ( hyper_rwds_i_d ),
        .hyper_dq_i      ( hyper_dq_i     ),
        .data_o          ( data_i         ),
        .enable          ( en_ddr_in      ),
        .rst_ni          ( rst_ni         ),
        .valid_o         ( data_i_valid   )
    );
    //Data from hyperram
    input_fifo i_input_fifo (
        .clk_i          ( clk0                      ),
        .rst_ni         ( rst_ni                    ),
        .data_i         ( data_i                    ),
        .en_write_i     ( en_ddr_in && data_i_valid ),
        .request_wait_o ( request_wait_read         ),
        .data_o         ( rx_data_o                 ),
        .valid_o        ( rx_valid_o                ),
        .ready_i        ( rx_ready_i                )
    );
    //Data to hyperram
    output_fifo i_output_fifo (
        .clk_i          ( clk0                      ),
        .rst_ni         ( rst_ni                    ),
        .data_i         ( {tx_strb_i, tx_data_i}    ),
        .valid_i        ( tx_valid_i                ),
        .ready_o        ( tx_ready_o                ),
        .data_o         ( { write_strb, write_data} ),
        .request_wait_o ( request_wait_write        ),
        .en_read_i      ( en_write                  ) 
    );

    always @* begin
        case(cmd_addr_sel)
            0: CA_out = cmd_addr[47:32];
            1: CA_out = cmd_addr[31:16];
            2: CA_out = cmd_addr[15:0];
            3: CA_out = write_data;
            default: CA_out = 16'b0;
        endcase // cmd_addr_sel
    end

    logic [3:0] wait_cnt;
    logic [BURST_WIDTH-1:0] burst_cnt;
    logic additional_latency;

    always_ff @(posedge clk0 or negedge rst_ni) begin : proc_hyper_trans_state
        if(~rst_ni) begin
            hyper_trans_state <= STANDBY;
            wait_cnt <= WAIT_CYCLES;
            burst_cnt <= {BURST_WIDTH{1'b0}};
            cmd_addr_sel <= 1'b0;
            additional_latency <= 1'b0;
        end else begin
            case(hyper_trans_state)
                STANDBY: begin
                    if(trans_valid_i) begin
                        hyper_trans_state <= SET_CMD_ADDR;
                        cmd_addr_sel <= 1'b0;
                        trans_ready_o <= 1'b1;
                    end
                end
                SET_CMD_ADDR: begin
                    cmd_addr_sel <= cmd_addr_sel + 1;
                    hyper_trans_state <= CMD_ADDR;
                end    
                CMD_ADDR: begin
                    cmd_addr_sel <= cmd_addr_sel + 1;
                    if(cmd_addr_sel == 2) begin
                        additional_latency <= hyper_rwds_i; //Sample RWDS after second part of CA is sent
                    end
                    if(cmd_addr_sel == 3) begin
                        if (local_address_space) begin //Write to memory config register
                            burst_cnt <= local_burst - 1;
                            hyper_trans_state <= REG_WRITE;
                        end else begin 
                            if (local_write) begin
                                wait_cnt <= WAIT_CYCLES - 2;
                            end else begin
                                wait_cnt <= WAIT_CYCLES - 1; //Data is delayed by one clock in ddr_in
                            end
                            if(additional_latency) begin
                                hyper_trans_state <= WAIT2;
                            end else begin
                                hyper_trans_state <= WAIT;
                            end
                        end
                    end
                end  
                REG_WRITE: begin
                        hyper_trans_state <= END;
                end
                WAIT2: begin  //Additional latency (If RWDS HIGH)
                    wait_cnt <= wait_cnt - 1;
                    if(wait_cnt == 4'h0) begin
                        wait_cnt <= WAIT_CYCLES - 1;
                        hyper_trans_state <= WAIT;
                    end
                end
                WAIT: begin  //t_ACC
                    wait_cnt <= wait_cnt - 1;
                    if(wait_cnt == 4'h0) begin
                        burst_cnt <= local_burst - 1;
                        if (local_write) begin
                            if(~request_wait_write) begin
                                hyper_trans_state <= DATA_W;
                            end else begin //Data to write not ready yet
                                hyper_trans_state <= WAIT_W;
                            end
                        end else begin
                            hyper_trans_state <= DATA_R;
                        end
                    end
                end
                DATA_R: begin
                    if(data_i_valid) begin 
                        burst_cnt <= burst_cnt - 1;
                    end
                    if(burst_cnt == {BURST_WIDTH{1'b0}}) begin
                        wait_cnt <= WAIT_CYCLES - 1;
                        hyper_trans_state <= END;
                    end else if(request_wait_read) begin
                        hyper_trans_state <= WAIT_R;
                    end
                end
                DATA_W: begin
                    burst_cnt <= burst_cnt - 1;
                    if(burst_cnt == {BURST_WIDTH{1'b0}}) begin
                        wait_cnt <= WAIT_CYCLES - 1;
                        hyper_trans_state <= END;
                    end else if (request_wait_write) begin
                        hyper_trans_state <= WAIT_W;
                    end
                end
                WAIT_R: begin
                    if(~request_wait_read) begin
                        hyper_trans_state <= DATA_R;
                    end
                end
                WAIT_W: begin
                    if(~request_wait_write) begin
                        hyper_trans_state <= START_DATA_W;
                    end
                end
                START_DATA_W: begin
                    hyper_trans_state <= DATA_W;
                end
                END: begin
                    wait_cnt <= wait_cnt - 1;
                    if(wait_cnt == 4'h0) begin //t_RWR
                        hyper_trans_state <= STANDBY;
                    end
                end
            endcase
            if(~trans_valid_i) begin
                trans_ready_o <= 1'b0;
            end 
        end
    end

    always @* begin
        //defaults
        clock_enable = 1'b1;
        en_cs = 1'b1;
        en_ddr_in = 1'b0;
        en_write = 1'b0;
        hyper_dq_oe_o = 1'b0;
        hyper_rwds_oe_o = 1'b0;
        en_read_transaction = 1'b0;

        case(hyper_trans_state)
            STANDBY: begin
                clock_enable = 1'b0;
                en_cs = 1'b0;
                en_read_transaction = 1'b1;
            end
            SET_CMD_ADDR: begin
                clock_enable = 1'b0;
            end
            CMD_ADDR: begin
                hyper_dq_oe_o = 1'b1;
            end
            REG_WRITE: begin
                hyper_dq_oe_o = 1'b1;
                en_write = 1'b1;
            end
            WAIT: begin  //t_ACC
                if(local_write == 1'b1) begin
                    hyper_rwds_oe_o = 1'b1;
                    if (wait_cnt == 4'b0000) begin
                        en_write = 1'b1;
                    end
                end
            end

            DATA_R: begin
                en_ddr_in = 1'b1;
            end
            WAIT_R: begin
                en_ddr_in = 1'b1;
            end
            DATA_W: begin
                hyper_dq_oe_o = 1'b1;
                hyper_rwds_oe_o = 1'b1;
                en_write = 1'b1;
            end

            WAIT_W: begin
                clock_enable = 1'b0;
                hyper_dq_oe_o = 1'b1;
                hyper_rwds_oe_o = 1'b1;
            end
            START_DATA_W: begin
                clock_enable = 1'b0;
                hyper_dq_oe_o = 1'b1;
                hyper_rwds_oe_o = 1'b1;
                en_write = 1'b1;
            end

            END: begin
                clock_enable = 1'b0;
                en_cs = 1'b0;
                en_read_transaction = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk0 or negedge rst_ni) begin : proc_local_transaction
        if(~rst_ni) begin
            local_address <= 32'h0;
            local_cs <= {NR_CS{1'b0}};
            local_write <= 1'b0;
            local_burst <= {BURST_WIDTH{1'b0}};
            local_address_space <= 1'b0;
        end else if(en_read_transaction) begin
            local_address <= trans_address_i;
            local_cs <= trans_cs_i;
            local_write <= trans_write_i;
            local_burst <= trans_burst_i;
            local_address_space <= trans_address_space_i;
        end
    end

endmodule
