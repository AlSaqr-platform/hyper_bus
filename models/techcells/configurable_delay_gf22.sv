// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module configurable_delay #(
	parameter int NUM_STEPS = 16
)(
  input  logic       clk_i,
  input  logic       enable_i,
  input  logic [3:0] delay_i,
  output logic       clk_o
);

   generic_delay_D4_O1_3P750_CG0 i_delay (
        .clk_i      ( clk_i     ),
        .delay_i    ( delay_i   ),
        .clk_o      ( clk_o     )
    );

endmodule