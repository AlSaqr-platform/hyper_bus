// Hyperbus splitter

// this code is unstable and most likely buggy
// it should not be used by anyone

// TODO: Add control with LAST

module hyperbus_splitter #(
  parameter int unsigned AxiDataWidth = -1
) (
  input logic       clk_i,
  input logic       rst_ni,
  input logic [2:0] size,
  input logic       first_rx,
  input logic       is_a_read,
  input logic       trans_handshake,
  input logic [1:0] start_addr,
  input logic [1:0] len,
  input logic       valid_i,
  input logic       last_i,
  output logic      valid_o,
  output logic      last_o,
  input logic       ready_i 
);

   localparam  int unsigned NumBytes = $clog2(AxiDataWidth);
   
   logic [3:0] start_addr_d, start_addr_q;
   logic [1:0] last_addr_d, last_addr_q, last_addr_comp;
   logic       len_overflow_d, len_overflow_q;
   logic       valid_d, valid_q;
   logic       last_d, last_q;
   logic [2:0] size_d, size_q;
   logic       mask_last;
   logic       split_rx;
   logic       is_16_bw, is_8_bw;
   logic       is_a_read_d, is_a_read_q;
   logic       is_misaligned_d, is_misaligned_q;
   logic       need_for_split;
   
   assign need_for_split = (split_rx | is_misaligned_d) & (size_d!=4);
   assign split_rx = is_16_bw | is_8_bw ;
   assign valid_o = ( need_for_split ) ? valid_d : valid_i;
   assign last_o = last_d & !mask_last;
   assign last_addr_comp = start_addr_q[1:0]+(1<<is_16_bw);
   assign is_8_bw = (size_d == 0);
   assign is_16_bw = (size_d == 1);
   
   always_comb begin : out_proc
      valid_d = valid_q;
      last_d = last_q;
      mask_last = 1'b0;
      if (valid_i) begin
         last_d = last_i;
      end
      if (valid_i & need_for_split) begin
         if (is_misaligned_d & first_rx) begin
            valid_d=1'b0;
         end else begin
            valid_d = 1'b1;
            if ( last_i & (last_addr_comp != last_addr_d) & !is_misaligned_d) begin
               mask_last = 1'b1;
            end
         end
      end else if ((start_addr_q==4 | start_addr_q==8 | is_misaligned_d) & (size_d!=4)) begin
         valid_d = 1'b0;
         last_d = 1'b0;
      end
   end
        
   always_comb begin : counter
      start_addr_d = start_addr_q;
      last_addr_d = last_addr_q;
      size_d = size_q;
      is_a_read_d = is_a_read_q;
      is_misaligned_d = is_misaligned_q;
      len_overflow_d = len_overflow_q;
      if (trans_handshake) begin
         start_addr_d[2] = 1'b0;
         start_addr_d = (size>1) ? '0 : start_addr ;
         last_addr_d = start_addr + (len<<size);
         size_d = size;
         len_overflow_d = (start_addr + (len<<size)) > NumBytes;
         is_a_read_d = is_a_read;
         is_misaligned_d = (start_addr[1:0]!='0) & (size>1);
      end else if ( last_d & (last_addr_comp == last_addr_d) ) begin 
         start_addr_d = 4;
      end else if ( start_addr_q == 4 ) begin
         start_addr_d = 0;
      end else if ( valid_d & ready_i ) begin
         start_addr_d = start_addr_q + (1<<size);
      end
   end
   
   
   always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff_splitter
       if (~rst_ni) begin
           valid_q <= '0;
           start_addr_q <= '0;
           last_addr_q <= '0;
           last_q <= '0;
           size_q <= '0;
           is_a_read_q <= '0;
           is_misaligned_q <= '0;
           len_overflow_q <= '0;
       end else begin
           valid_q <= valid_d;
           start_addr_q <= start_addr_d;
           last_addr_q <= last_addr_d;
           last_q <= last_d;
           size_q <= size_d;
           is_a_read_q <= is_a_read_d;
           is_misaligned_q <= is_misaligned_d;
           len_overflow_q <= len_overflow_d;
       end
   end            

  read_bandwidth : assert property(
      @(posedge clk_i) (is_16_bw && start_addr_q==4) |-> !valid_i)
        else $fatal (1, "Not enough bandwidth in the sys side");

endmodule
