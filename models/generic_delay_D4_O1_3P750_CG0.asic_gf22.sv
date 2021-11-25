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


/// delay line
`timescale 1 ps/1 ps

module generic_delay_D4_O1_3P750_CG0 (
    input  logic  clk_i,
    output logic  clk_o,
    input  logic enable_i,
    input  [4-1:0] delay_i
);
   localparam  BIT_WIDTH = 4;
   localparam  N_WIRE = -1*(1-2**(BIT_WIDTH));
   localparam  N_PATH = 2**(BIT_WIDTH);
   logic       [N_WIRE-1:0]    mux_out;
   logic       [N_PATH-1:0]    first_input;

   assign clk_o = mux_out[0];     
   genvar i;

   // delay_path
   generate 
       for( i = 0; i < N_PATH; i++)
          begin
            assign first_input[i] = clk_i;
          end
   endgenerate

   // tree of mux
   genvar j,k;
   generate
     for( j = 0; j < BIT_WIDTH; j++)
        begin
           for( k = 0; k < 2**(j+1); k = k+2)
              begin
                if(j== BIT_WIDTH-1)
                   begin
                     tc_clk_mux2 i_clk_mux
                     (
                         .clk0_i    ( first_input[k]          ),
                         .clk1_i    ( first_input[k+1]        ),
                         .clk_sel_i ( delay_i[BIT_WIDTH-1-j]  ),
                         .clk_o     ( mux_out[k/2-1*(1-2**j)] )
                     );
                   end
                else
                   begin
                     tc_clk_mux2 i_clk_mux
                     (
                         .clk0_i    ( mux_out[k-1*(1-2**(j+1))]   ),
                         .clk1_i    ( mux_out[k+1-1*(1-2**(j+1))] ),
                         .clk_sel_i ( delay_i[BIT_WIDTH-1-j]      ),
                         .clk_o     ( mux_out[k/2-1*(1-2**j)]     )
                     );
                   end

              end
        end 
   endgenerate

endmodule
