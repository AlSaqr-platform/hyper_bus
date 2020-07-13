// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Description: Configuration for Hyperbus, v2 (For fixed 32-bit address spaces!)

module hyperbus_cfg_regs #(
  parameter int unsigned NumChips   = 2,
  input logic     clk_i,
  input logic     rst_ni,

  input  reg_intf_pkg::req_a32_d32        reg_req_i,
  output reg_intf_pkg::rsp_d32            reg_rsp_o,

  output hyperbus_pkg::hyperbus_cfg_t     cfg_o,
  output logic [NumChips-1:0][1:0][31:0]  chip_addr_range_o,
);
  `include "common_cells/registers.svh"

  // Parameters
  localparam int unsigned NumRegs   = 2*NumChips + 6;
  localparam int unsigned RegsBits  = $clog2(NumRegs)
  localparam int unsigned AddrWidth = RegsBits + 2;

  // Registers
  hyperbus_pkg::hyperbus_cfg_t    cfg_d, cfg_q, cfg_rstval;
  logic [NumChips-1:0][1:0][31:0] crange_d, crange_q, crange_rstval;

  // Local signals
  logic [RegsBits-1:0]  sel_reg;
  logic                 sel_reg_mapped;

  // Regbus
  assign sel_reg         = reg_req_i.addr[AddrWidth-1:2];
  assign sel_reg_mapped  = (sel_reg >= NumRegs);

  assign reg_rsp_o.ready = 1'b1;
  assign reg_rsp_o.error = reg_req_i.valid & ~sel_reg_mapped;

  always_comb begin : proc_read
    reg_rsp_o.rdata = '0;
    if (sel_reg_mapped) begin
      logic [NumRegs-1:0][31:0] rfield = {
        crange_q,
        32'(cfg_q.t_t_variable_latency_check),
        32'(cfg_q.t_t_rwds_delay_line),
        32'(cfg_q.t_t_read_write_recovery),
        32'(cfg_q.t_t_cs_max),
        32'(cfg_q.t_en_latency_additional),
        32'(cfg_q.t_t_latency_access),
      }
      reg_rsp_o.rdata = rfield[sel_reg];
      endcase
    end
  end

  always_comb begin : proc_write
    cfg_d     = cfg_q;
    crange_d  = crange_q;
    if (reg_req_i.valid & reg_req_i.write & sel_reg_mapped) begin
      logic [3:0] ws = reg_req_i.wstrb;
      logic [31:0] wm = {{4{ws[3]}}, {4{ws[2]}}, {4{ws[1]}}, {4{ws[0]}}};
      case (sel_reg) begin
        'h0: cfg_d.t_latency_access         = (~wm & cfg_q.t_latency_access        ) | (wm & reg_req_i.wdata);
        'h1: cfg_d.en_latency_additional    = (~wm & cfg_q.en_latency_additional   ) | (wm & reg_req_i.wdata);
        'h2: cfg_d.t_cs_max                 = (~wm & cfg_q.t_cs_max                ) | (wm & reg_req_i.wdata);
        'h3: cfg_d.t_read_write_recovery    = (~wm & cfg_q.t_read_write_recovery   ) | (wm & reg_req_i.wdata);
        'h4: cfg_d.t_rwds_delay_line        = (~wm & cfg_q.t_rwds_delay_line       ) | (wm & reg_req_i.wdata);
        'h5: cfg_d.t_variable_latency_check = (~wm & cfg_q.t_variable_latency_check) | (wm & reg_req_i.wdata);
        default: begin
          logic  chip_reg;
          logic [$clog2(NumChips)-1:0] sel_chip;
          {sel_chip, chip_reg} = sel_reg - 'h6;     // Bad regfile layouts have consequences...
          crange_d[sel_chip][chip_reg] = (~wm & crange_q[sel_chip][chip_reg]) |  (wm & reg_req_i.wdata);
        end
      end
    end
  end

  // Register reset values
  assign cfg_rstval = hyperbus_pkg::hyperbus_cfg_t'{
    t_latency_access:         'h6,
    en_latency_additional:    'b1,
    t_cs_max:                 'd665,
    t_read_write_recovery:    'h6,
    t_rwds_delay_line:        'h2,
    t_variable_latency_check: 'h3
  };

  for (genvar i = 0; unsigned'(i) < NumChips; i++) begin
      assign crange_rstval[i][0] = 'h40_0000 * i;
      assign crange_rstval[i][1] = 'h40_0000 * (i+1);  // Address decoder: end noninclusive
  end

  // Registers
  `FFARN(cfg_q, cfg_d, cfg_rstval, clk_i, rst_ni);
  `FFARN(crange_q, crange_d, crange_rstval, clk_i, rst_ni);

  // Outputs
  assign cfg_o              = cfg_q;
  assign chip_addr_range_o  = crange_q;

endmodule