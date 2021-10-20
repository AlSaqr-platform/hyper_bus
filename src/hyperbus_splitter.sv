// Hyperbus splitter

// this code is unstable and most likely buggy
// it should not be used by anyone

// TODO: Add control with LAST

module hyperbus_splitter 
(
  input logic       clk_i,
  input logic       rst_ni,
  input logic       is_16_bw,
  input logic       is_8_bw,
  input logic       trans_handshake,
  input logic [1:0] start_addr,
  input logic [1:0] len,
  input logic       valid_i,
  input logic       last_i,
  output logic      valid_o,
  output logic      last_o,
  input logic       ready_i 
);

   logic [2:0] start_addr_d, start_addr_q;
   logic [1:0] last_addr_d, last_addr_q, last_addr_comp;
   logic       valid_d, valid_q;
   logic       last_d, last_q;
   logic       mask_last;
   logic       split_rx;

   assign split_rx = is_16_bw | is_8_bw ;
   assign valid_o = ( split_rx ) ? valid_d : valid_i;
   assign last_o = last_d & !mask_last;
   assign last_addr_comp = start_addr_q[1:0]+(1<<is_16_bw);
   
   
   always_comb begin : out_proc
      valid_d = valid_q;
      last_d = last_q;
      mask_last = 1'b0;
      if (valid_i) begin
         last_d = last_i;
      end
      if (valid_i & split_rx) begin
         valid_d = 1'b1;
         if ( last_i & (last_addr_comp != last_addr_d) ) begin
            mask_last = 1'b1;
         end
      end else if (start_addr_q==4) begin
         valid_d = 1'b0;
         last_d = 1'b0;
      end
   end
        
   always_comb begin : counter
      start_addr_d = start_addr_q;
      last_addr_d = last_addr_q; 
      if (trans_handshake) begin
         start_addr_d[2] = 1'b0;
         start_addr_d = start_addr;
         last_addr_d = start_addr + (len<<is_16_bw);
      end else if ( last_d & (last_addr_comp == last_addr_d) ) begin //(last_addr_d[1] | last_addr_d[0]) ) begin
         start_addr_d = 4;
      end else if ( start_addr_q == 4 ) begin
         start_addr_d = 0;
      end else if ( valid_d & ready_i ) begin
         start_addr_d = start_addr_q + (1<<is_16_bw);
      end
   end
   
   
   always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff_splitter
       if (~rst_ni) begin
           valid_q <= '0;
           start_addr_q <= '0;
           last_addr_q <= '0;
           last_q <= '0;
       end else begin
           valid_q <= valid_d;
           start_addr_q <= start_addr_d;
           last_addr_q <= last_addr_d;
           last_q <= last_d;
       end
   end            

  read_bandwidth : assert property(
      @(posedge clk_i) (is_16_bw && start_addr_q==4) |-> !valid_i)
        else $fatal (1, "Not enough bandwidth in the sys side");

endmodule
