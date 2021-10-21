// Hyperbus upsizer

// this code is unstable and most likely buggy
// it should not be used by anyone

module hyperbus_upsizer  #(
  parameter int unsigned AxiDataWidth = -1, 
  parameter int unsigned BurstLength = -1,
  parameter type T = logic,
  parameter int unsigned AddrWidth = $clog2(AxiDataWidth/8) 
) (
  input logic                   clk_i,
  input logic                   rst_ni,
  input logic [2:0]             size,
  input logic [AddrWidth-1:0]   start_addr,
  input logic [BurstLength-1:0] len,
  input logic                   is_a_write,
  input logic                   trans_handshake, 
  input logic                   first_tx,
  input logic                   valid_i,
  output logic                  sel_o,
  output logic                  ready_o,
  input                         T data_i,
  output logic                  valid_o,
  input logic                   ready_i,
  output                        T data_o
);

   typedef enum logic [2:0] {
       Idle,
       Sample,
       WaitReady,
       WaitNextTrans
   } hyper_upsizer_state_t;
                             
   hyper_upsizer_state_t state_d,    state_q;
   T data_buffer_d, data_buffer_q;

   logic        is_16_bw, is_8_bw;
   logic        upsize;

   logic [AddrWidth-1:0] byte_idx_d, byte_idx_q;
   logic [AddrWidth-1:0] last_addr_d, last_addr_q;
   logic [3:0]           size_d, size_q;
   

   assign is_8_bw = (size_d == 0);
   assign is_16_bw = (size_d == 1) ;
   assign upsize = is_16_bw | is_8_bw ;
 // | (start_addr[1:0]!=2'b00);
   assign sel_o = !upsize ;
   assign data_o = data_buffer_q;   
   
   always_comb begin : counter
      byte_idx_d = byte_idx_q;
      size_d = size_q;
      if (trans_handshake) begin
         byte_idx_d = start_addr;
         size_d = size;
         last_addr_d = start_addr + (len<<size_d);
      end else if ( valid_i & ready_o ) begin
         byte_idx_d = byte_idx_q + (1<<size_d);
      end
   end // block: counter

   always_comb begin : sampler
      data_buffer_d = data_buffer_q;
      if ( (state_q==WaitNextTrans) | (state_q==Idle) ) begin
         data_buffer_d.last = '0;
      end else if (state_q == Sample & valid_i) begin
         if ( (byte_idx_q[1:0]!=0) && first_tx ) begin
            data_buffer_d = data_i;
            data_buffer_d.strb[byte_idx_q-1 -: 3] = '0;
            data_buffer_d.strb[byte_idx_q] = 1'b1;
         end else if (data_i.last && (byte_idx_d==last_addr_q)) begin
            data_buffer_d.data[byte_idx_q*8 +: 32] = data_i.data[byte_idx_q*8 +: 32];
            data_buffer_d.strb[byte_idx_q] = 1'b1;
            data_buffer_d.strb[byte_idx_q+1] = is_16_bw;
            data_buffer_d.strb[byte_idx_q+2 +: 2] = '0;
            data_buffer_d.last = 1'b1;
         end else begin
            data_buffer_d.data[byte_idx_q*8 +: 32] = data_i.data[byte_idx_q*8 +: 32];
            data_buffer_d.strb[byte_idx_q +: 4] = data_i.strb[byte_idx_q +: 4];
            data_buffer_d.last = data_i.last;
         end 
      end 
   end 
   
 

   always_comb begin : fsm
      state_d = state_q;
      case (state_q)
        Idle: begin
           if (upsize) begin
              state_d = Sample;
           end
        end
        Sample: begin
           if (byte_idx_d[1:0]==2'b00 & valid_i & ready_o ) begin 
              state_d = WaitReady;
           end else if (data_buffer_q.last) begin
              state_d = WaitReady;
           end
        end
        WaitReady: begin
           if (ready_i) begin
              if (upsize) begin
                 if (data_buffer_q.last)
                   state_d = WaitNextTrans;
                 else
                   state_d = Sample;
              end else begin
                 state_d = Idle;
              end
           end
        end
        WaitNextTrans: begin
           if (trans_handshake & is_a_write)
             state_d = Sample;
        end
      endcase 
   end // block: fsm

   always_comb begin : valid_ready
      valid_o = 1'b0;
      ready_o = 1'b0;
      case (state_q)
        Idle: begin
           valid_o = 1'b0;
           ready_o = 1'b0;
        end
        Sample: begin
           valid_o = 1'b0;
           ready_o = 1'b1;
        end
        WaitReady: begin
           valid_o = 1'b1;
           ready_o = 1'b0;
        end
        WaitNextTrans: begin
           valid_o = 1'b0;
           ready_o = 1'b0;
        end
      endcase 
   end 
   
   always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff_phy
       if (~rst_ni) begin
           data_buffer_q <= '0;
           state_q <= Idle;
           byte_idx_q <= '0;
           size_q <= '0;
           last_addr_q <= '0;
       end else begin
           state_q <= state_d;
           data_buffer_q <= data_buffer_d;
           byte_idx_q <= byte_idx_d;
           size_q <= size_d;
           last_addr_q <= last_addr_d;
       end
   end            


endmodule
                         
