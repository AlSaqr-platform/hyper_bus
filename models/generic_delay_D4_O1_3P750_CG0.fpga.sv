`timescale 1ps/1ps

(* no_ungroup *)
(* no_boundary_optimization *)
module generic_delay_D4_O1_3P750_CG0 (
  input  logic       clk_i,
  input  logic       enable_i,
  input  logic [4-1:0] delay_i,
  output logic [1-1:0] clk_o
);

  IBUF #
    (
     .IBUF_LOW_PWR ("FALSE")
     ) u_ibufg_sys_clk_o
      (
       .I  (clk_i),
       .O  (clk_o[0])
       );

endmodule

