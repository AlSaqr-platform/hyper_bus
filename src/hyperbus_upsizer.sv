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

   localparam NumBitStrb = AxiDataWidth/8;
   typedef enum logic [2:0] {
       Idle,
       Sample,
       WaitReady,
       WaitNextTrans,
       SplitLastTransfer
   } hyper_upsizer_state_t;
                             
   hyper_upsizer_state_t state_d,    state_q;
   T data_buffer_d, data_buffer_q;

   int          i;
   
   logic        is_16_bw, is_8_bw;
   logic        upsize;
   logic        split_ltx;
   logic        mask_last;
   logic        test_s;
   
   logic [AddrWidth-1:0] byte_idx_d, byte_idx_q;
   logic [AddrWidth-1:0] start_addr_d, start_addr_q;
   logic [AddrWidth-1:0] last_addr_d, last_addr_q;
   logic [3:0]           size_d, size_q;
   logic [AddrWidth-1:0] addr_sample [NumBitStrb-1:0];
   

   assign is_8_bw = (size_d == 0);
   assign is_16_bw = (size_d == 1) ;
   assign upsize = is_16_bw | is_8_bw ;
   assign split_ltx = (start_addr_d[1:0]!='0 & !is_16_bw & !is_8_bw & (size_d!=4));
   assign sel_o = ! (upsize | split_ltx) ;
   assign data_o.data = data_buffer_q.data;
   assign data_o.strb = data_buffer_q.strb;
   assign data_o.user = data_buffer_q.user;
   assign data_o.last = data_buffer_q.last & !mask_last;
                        
   always_comb begin : counter
      byte_idx_d = byte_idx_q;
      size_d = size_q;
      start_addr_d = start_addr_q;
      last_addr_d = last_addr_q;
       if (trans_handshake) begin
         start_addr_d = start_addr;
         byte_idx_d = start_addr;
         size_d = size;
         last_addr_d = start_addr + (len<<size_d);
      end else if ( valid_i & ready_o ) begin
         byte_idx_d = byte_idx_q + (1<<size_d);
      end
   end 

   always_comb begin : sampler
      data_buffer_d = data_buffer_q;
      if ( (state_q==WaitNextTrans) | (state_q==Idle) ) begin
         data_buffer_d.last = '0;
      end else if (state_q == Sample & valid_i) begin
         if ( (byte_idx_q[1:0]!=0) && first_tx ) begin
            data_buffer_d = data_i;
            data_buffer_d.strb[byte_idx_q-1 -: 3] = '0;
            data_buffer_d.strb[byte_idx_q] = data_i.strb[byte_idx_q];
         end else if (data_i.last && (byte_idx_d==last_addr_q)) begin
            data_buffer_d.data[byte_idx_q*8 +: AxiDataWidth] = data_i.data[byte_idx_q*8 +: AxiDataWidth];
            data_buffer_d.strb[byte_idx_q +: NumBitStrb] = data_i.strb[byte_idx_q +: NumBitStrb];
            data_buffer_d.strb[byte_idx_q+1] = (size_d>0) & data_i.strb[byte_idx_q+1];
            data_buffer_d.strb[byte_idx_q+2] = (size_d>1) & data_i.strb[byte_idx_q+2];
            data_buffer_d.strb[byte_idx_q+3] = (size_d>1) & data_i.strb[byte_idx_q+3];
            data_buffer_d.strb[byte_idx_q+4] = (size_d>2) & data_i.strb[byte_idx_q+4];
            data_buffer_d.strb[byte_idx_q+5] = (size_d>2) & data_i.strb[byte_idx_q+5];
            data_buffer_d.strb[byte_idx_q+6] = (size_d>2) & data_i.strb[byte_idx_q+6];
            data_buffer_d.strb[byte_idx_q+7] = (size_d>2) & data_i.strb[byte_idx_q+7];
            data_buffer_d.last = 1'b1;
         end else begin
            data_buffer_d.data[byte_idx_q*8 +: AxiDataWidth] = data_i.data[byte_idx_q*8 +: AxiDataWidth];
            data_buffer_d.last = data_i.last;
            data_buffer_d.strb[byte_idx_q +: NumBitStrb] = data_i.strb[byte_idx_q +: NumBitStrb];
            if (byte_idx_q+(2**size_d)>NumBitStrb) begin
               data_buffer_d.strb[0] = 1'b0;
               data_buffer_d.strb[1] = (byte_idx_q+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[1];
               data_buffer_d.strb[2] = (byte_idx_q+1+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[2];
               data_buffer_d.strb[3] = (byte_idx_q+2+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[3];
               data_buffer_d.strb[4] = (byte_idx_q+3+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[4];
               data_buffer_d.strb[5] = (byte_idx_q+4+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[5];
               data_buffer_d.strb[6] = (byte_idx_q+5+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[6];
               data_buffer_d.strb[7] = (byte_idx_q+6+(1<<size_d))>NumBitStrb ? 1'b0 : data_buffer_q.strb[7];
            end 
         end 
      end 
   end 
   
 

   always_comb begin : fsm
      state_d = state_q;
      case (state_q)
        Idle: begin
           if (upsize | split_ltx) begin
              state_d = Sample;
           end
        end
        Sample: begin
           if (upsize & !split_ltx) begin
              if (byte_idx_d[1:0]==2'b00 & valid_i & ready_o) begin
                 state_d = WaitReady;
              end else if (data_buffer_q.last) begin
                 state_d = WaitReady;
              end
           end else if (!upsize & split_ltx & (valid_i & ready_o)) begin
                state_d = data_buffer_d.last ? SplitLastTransfer : WaitReady;
           end else if (!upsize & !split_ltx) begin
              state_d = Idle;
           end
        end
        WaitReady: begin
           if (ready_i) begin
              if (upsize | split_ltx) begin
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
        SplitLastTransfer: begin
           if (ready_i) begin
              state_d = WaitReady;
           end
        end
      endcase 
   end // block: fsm

   always_comb begin : valid_ready
      valid_o = 1'b0;
      ready_o = 1'b0;
      mask_last = 1'b0;
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
        SplitLastTransfer: begin
           valid_o = 1'b1;
           ready_o = 1'b0;
           mask_last = 1'b1;
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
           start_addr_q <= '0;
       end else begin
           state_q <= state_d;
           data_buffer_q <= data_buffer_d;
           byte_idx_q <= byte_idx_d;
           size_q <= size_d;
           last_addr_q <= last_addr_d;
           start_addr_q <= start_addr_d;
       end
   end            


endmodule
                         
