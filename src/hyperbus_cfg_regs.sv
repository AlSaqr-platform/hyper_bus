// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Description: Configuration for Hyperbus, v2 (For fixed 32-bit address spaces!)

module hyperbus_cfg_regs #(
    parameter int unsigned NumChips = -1,
    parameter type         reg_req_t       = logic,
    parameter type         reg_rsp_t       = logic,
    parameter type         rule_t   = logic
) (
    input logic     clk_i,
    input logic     rst_ni,

    input  reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,

    output hyperbus_pkg::hyper_cfg_t    cfg_o,
    output rule_t [NumChips-1:0]        chip_rules_o
);
    `include "common_cells/registers.svh"

    // Parameters
    localparam int unsigned NumRegs     = 2*NumChips + 6;
    localparam int unsigned RegsBits    = $clog2(NumRegs);
    localparam int unsigned AddrWidth   = RegsBits + 2;

    // Registers
    hyperbus_pkg::hyper_cfg_t    cfg_d, cfg_q, cfg_rstval;
    logic [NumChips-1:0][1:0][31:0] crange_d, crange_q, crange_rstval;

    // Local signals
    logic [RegsBits-1:0]  sel_reg;
    logic                 sel_reg_mapped;

    // Regbus
    assign sel_reg          = reg_req_i.addr[AddrWidth-1:2];
    assign sel_reg_mapped   = (sel_reg < NumRegs);

    assign reg_rsp_o.ready  = 1'b1;
    assign reg_rsp_o.error  = reg_req_i.valid & ~sel_reg_mapped;

    always_comb begin : proc_read
        logic [NumRegs-1:0][31:0] rfield;
        reg_rsp_o.rdata = '0;
        if (sel_reg_mapped) begin
            rfield = {
                crange_q,
                32'(cfg_q.address_space),
                32'(cfg_q.t_variable_latency_check),
                32'(cfg_q.t_tx_clk_delay),
                32'(cfg_q.t_rx_clk_delay),
                32'(cfg_q.t_read_write_recovery),
                32'(cfg_q.t_burst_max),
                32'(cfg_q.en_latency_additional),
                32'(cfg_q.t_latency_access)
            };
            reg_rsp_o.rdata = rfield[sel_reg];
        end
    end

    always_comb begin : proc_write
        logic [3:0] ws;
        logic [31:0] wm;
        logic  chip_reg;
        logic [$clog2(NumChips)-1:0] sel_chip;
        cfg_d     = cfg_q;
        crange_d  = crange_q;
        if (reg_req_i.valid & reg_req_i.write & sel_reg_mapped) begin
            ws = reg_req_i.wstrb;
            wm = {{4{ws[3]}}, {4{ws[2]}}, {4{ws[1]}}, {4{ws[0]}}};
            case (sel_reg)
                'h0: cfg_d.t_latency_access         = (~wm & cfg_q.t_latency_access        ) | (wm & reg_req_i.wdata);
                'h1: cfg_d.en_latency_additional    = (~wm & cfg_q.en_latency_additional   ) | (wm & reg_req_i.wdata);
                'h2: cfg_d.t_burst_max              = (~wm & cfg_q.t_burst_max             ) | (wm & reg_req_i.wdata);
                'h3: cfg_d.t_read_write_recovery    = (~wm & cfg_q.t_read_write_recovery   ) | (wm & reg_req_i.wdata);
                'h4: cfg_d.t_rx_clk_delay           = (~wm & cfg_q.t_rx_clk_delay          ) | (wm & reg_req_i.wdata);
                'h5: cfg_d.t_tx_clk_delay           = (~wm & cfg_q.t_tx_clk_delay          ) | (wm & reg_req_i.wdata);
                'h6: cfg_d.t_variable_latency_check = (~wm & cfg_q.t_variable_latency_check) | (wm & reg_req_i.wdata);
                'h7: cfg_d.address_space            = (~wm & cfg_q.address_space           ) | (wm & reg_req_i.wdata);
                default: begin
                    {sel_chip, chip_reg} = sel_reg - 'h8;     // Bad regfile layouts have consequences...
                    crange_d[sel_chip][chip_reg] = (~wm & crange_q[sel_chip][chip_reg]) |  (wm & reg_req_i.wdata);
                end
            endcase // sel_reg
        end
    end

    // Register reset values
    assign cfg_rstval = hyperbus_pkg::hyper_cfg_t'{
        t_latency_access:           'h6,
        en_latency_additional:      'b1,
        t_burst_max:                'd665,
        t_read_write_recovery:      'h6,
        t_rx_clk_delay:             'h8,
        t_tx_clk_delay:             'h8,
        t_variable_latency_check:   'h3,
        address_space:              'b0
    };

    for (genvar i = 0; unsigned'(i) < NumChips; i++) begin : gen_crange_rstval
            assign crange_rstval[i][0]  = 'h40_0000 * i;
            assign crange_rstval[i][1]  = 'h40_0000 * (i+1);  // Address decoder: end noninclusive
    end

    // Registers
    `FFARN(cfg_q, cfg_d, cfg_rstval, clk_i, rst_ni);
    `FFARN(crange_q, crange_d, crange_rstval, clk_i, rst_ni);

    // Outputs
    assign cfg_o  = cfg_q;
    for (genvar i = 0; unsigned'(i) < NumChips; ++i ) begin : gen_crange_out
        assign chip_rules_o[i].idx         = unsigned'(i);   // No overlap: keep indices sequential
        assign chip_rules_o[i].start_addr  = crange_q[i][0];
        assign chip_rules_o[i].end_addr    = crange_q[i][1];
    end

endmodule : hyperbus_cfg_regs
