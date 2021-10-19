// Hyperbus upsizer

// this code is unstable and most likely buggy
// it should not be used by anyone

module hyperbus_upsizer #(
  parameter type T      = logic
) (
  input logic  clk_i ,
  input logic  rst_ni ,
  input logic  is_16_bw ,
  output logic sel_o ,
  input logic  start_addr ,
  input logic  trans_handshake , 
  input logic  first_tx ,
  input logic  valid_i ,
  output logic ready_o ,
  input        T data_i ,
  output logic valid_o ,
  input logic  ready_i ,
  output       T data_o
);

   typedef enum logic [2:0] {
       Idle,
       Sample,
       WaitReady
   } hyper_upsizer_state_t;
                             
   hyper_upsizer_state_t state_d,    state_q;
   T data_buffer_d, data_buffer_q;
   logic [3:0]      counter_d, counter_q;
   logic [4:0]      word_idx_d, word_idx_q;

   assign sel_o = !is_16_bw;
   assign data_o = data_buffer_q;

   always_comb begin : fsm
      state_d = state_q;
      case (state_q)
        Idle: begin
           if (is_16_bw) begin
              state_d = Sample;
           end
        end
        Sample: begin
           if (counter_d==2) begin
              state_d = WaitReady;
           end
        end
        WaitReady: begin
           if (ready_i) begin
              if (is_16_bw) begin
                 state_d = Sample;
              end else begin
                 state_d = Idle;
              end
           end
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
      endcase // case (state_d)
   end // block: valid_ready
      
   
   always_comb begin : counter
      counter_d = counter_q;
      word_idx_d = word_idx_q;
      if (trans_handshake) begin
         counter_d[3:1] = '0;
         counter_d[0] = start_addr;
         word_idx_d[4:1] = '0;
         word_idx_d[0] = start_addr;
      end else if ( valid_i & data_i.last ) begin
         counter_d = 2;
      end else if ( counter_q == 2 ) begin
         counter_d = 0;
      end else if ( valid_i & ready_o ) begin
         counter_d = counter_q + 1;
         word_idx_d = word_idx_q + 1;
      end
   end // block: counter

   always_comb begin : sampler
      data_buffer_d = data_buffer_q;
      if (state_q == Sample & valid_i) begin
         if ( start_addr && first_tx ) begin
           data_buffer_d = data_i;
           data_buffer_d.strb[1:0] = '0;
         end else if ( data_i.last && counter_q==0 ) begin
           data_buffer_d.data[word_idx_q*16 +: 16] = data_i.data[word_idx_q*16 +: 16];
           data_buffer_d.strb[word_idx_q*2 +: 2] = data_i.strb[word_idx_q*2 +: 2];
           data_buffer_d.strb[word_idx_q*2 +2 +: 2] = '0;
         end else begin
           data_buffer_d.data[word_idx_q*16 +: 16] = data_i.data[word_idx_q*16 +: 16];
           data_buffer_d.strb[word_idx_q*2 +: 2] = data_i.strb[word_idx_q*2 +: 2];
         end
      end
   end 
   
   always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff_phy
       if (~rst_ni) begin
           data_buffer_q <= '0;
           state_q <= Idle;
           counter_q <= '0;
           word_idx_q <= '0;
       end else begin
           state_q <= state_d;
           data_buffer_q <= data_buffer_d;
           counter_q <= counter_d;
           word_idx_q <= word_idx_d;
       end
   end            


endmodule
                         
