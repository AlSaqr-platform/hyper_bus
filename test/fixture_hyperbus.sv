// Hyperbus Fixture

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "register_interface/typedef.svh"

module fixture_hyperbus #(
    parameter int unsigned NumChips = 2
);

    localparam time SYS_TCK  = 2.78ns;
    localparam time SYS_TA   = 1ns;
    localparam time SYS_TT   = SYS_TCK - 1ns;

    localparam time PHY_TCK  = 10ns;

    logic sys_clk      = 0;
    logic phy_clk      = 0;
    logic test_mode    = 0;
    logic rst_n        = 1;
    logic eos          = 0; // end of sim

    // -------------------- AXI drivers --------------------

    localparam AxiAw  = 32;
    localparam AxiDw  = 128;
    localparam AxiIw  = 6;

    localparam RegAw  = 32;
    localparam RegDw  = 32;

    typedef axi_pkg::xbar_rule_32_t rule_t;

    typedef logic [AxiAw-1:0]   axi_addr_t;
    typedef logic [AxiDw-1:0]   axi_data_t;
    typedef logic [AxiDw/8-1:0] axi_strb_t;
    typedef logic [AxiIw-1:0]   axi_id_t;

    `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, axi_addr_t, axi_id_t, logic [0:0])
    `AXI_TYPEDEF_W_CHAN_T(w_chan_t, axi_data_t, axi_strb_t, logic [0:0])
    `AXI_TYPEDEF_B_CHAN_T(b_chan_t, axi_id_t, logic [0:0])
    `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, axi_addr_t, axi_id_t, logic [0:0])
    `AXI_TYPEDEF_R_CHAN_T(r_chan_t, axi_data_t, axi_id_t, logic [0:0])
    `AXI_TYPEDEF_REQ_T(req_t, aw_chan_t, w_chan_t, ar_chan_t)
    `AXI_TYPEDEF_RESP_T(resp_t, b_chan_t, r_chan_t)

    req_t   axi_master_req;
    resp_t  axi_master_rsp;

    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(AxiAw ),
        .AXI_DATA_WIDTH(AxiDw ),
        .AXI_ID_WIDTH  (AxiIw ),
        .AXI_USER_WIDTH(1     )
    ) axi_dv(sys_clk);

    AXI_BUS #(
        .AXI_ADDR_WIDTH(AxiAw ),
        .AXI_DATA_WIDTH(AxiDw ),
        .AXI_ID_WIDTH  (AxiIw ),
        .AXI_USER_WIDTH(1     )
    ) axi_master();

    `AXI_ASSIGN(axi_master, axi_dv)

    `AXI_ASSIGN_TO_REQ(axi_master_req, axi_master)
    `AXI_ASSIGN_FROM_RESP(axi_master, axi_master_rsp)

    typedef axi_test::axi_driver #(.AW(AxiAw ), .DW(AxiDw ), .IW(AxiIw ), .UW(1), .TA(SYS_TA), .TT(SYS_TT)) axi_drv_t;
    axi_drv_t axi_master_drv = new(axi_dv);

    axi_test::axi_ax_beat #(.AW(AxiAw ), .IW(AxiIw ), .UW(1)) ar_beat = new();
    axi_test::axi_r_beat  #(.DW(AxiDw ), .IW(AxiIw ), .UW(1)) r_beat  = new();
    axi_test::axi_ax_beat #(.AW(AxiAw ), .IW(AxiIw ), .UW(1)) aw_beat = new();
    axi_test::axi_w_beat  #(.DW(AxiDw ), .UW(1))              w_beat  = new();
    axi_test::axi_b_beat  #(.IW(AxiIw ), .UW(1))              b_beat  = new();

    // -------------------------- Regbus driver --------------------------

    typedef logic [RegAw-1:0]   reg_addr_t;
    typedef logic [RegDw-1:0]   reg_data_t;
    typedef logic [RegDw/8-1:0] reg_strb_t;

    `REG_BUS_TYPEDEF_REQ(reg_req_t, reg_addr_t, reg_data_t, reg_strb_t)
    `REG_BUS_TYPEDEF_RSP(reg_rsp_t, reg_data_t)

    reg_req_t   reg_req;
    reg_rsp_t   reg_rsp;

    REG_BUS #(
        .ADDR_WIDTH( RegAw ),
        .DATA_WIDTH( RegDw )
    ) i_rbus (
        .clk_i (sys_clk)
    );

    reg_test::reg_driver #(
        .AW ( RegAw  ),
        .DW ( RegDw  ),
        .TA ( SYS_TA ),
        .TT ( SYS_TT )
    ) i_rmaster = new( i_rbus );

    assign reg_req = reg_req_t'{
        addr:   i_rbus.addr,
        write:  i_rbus.write,
        wdata:  i_rbus.wdata,
        wstrb:  i_rbus.wstrb,
        valid:  i_rbus.valid
    };

    assign i_rbus.rdata = reg_rsp.rdata;
    assign i_rbus.ready = reg_rsp.ready;
    assign i_rbus.error = reg_rsp.error;

    // -------------------------- DUT --------------------------

    wire  [1:0] hyper_cs_n_wire;
    wire        hyper_ck_wire;
    wire        hyper_ck_n_wire;
    wire        hyper_rwds_o;
    wire        hyper_rwds_i;
    wire        hyper_rwds_oe;
    wire        hyper_rwds_wire;

    wire  [7:0] hyper_dq_i;
    wire  [7:0] hyper_dq_o;
    wire        hyper_dq_oe;
    wire  [7:0] hyper_dq_wire;

    wire        hyper_reset_n_wire;

    tristate_shim i_tristate_shim_rwds (
        .out_ena_i  ( hyper_rwds_oe   ),
        .out_i      ( hyper_rwds_o    ),
        .in_o       ( hyper_rwds_i    ),
        .line_io    ( hyper_rwds_wire )
    );

    for (genvar i = 0; i < 8; i++) begin
        tristate_shim i_tristate_shim_dq (
            .out_ena_i  ( hyper_dq_oe       ),
            .out_i      ( hyper_dq_o    [i] ),
            .in_o       ( hyper_dq_i    [i] ),
            .line_io    ( hyper_dq_wire [i] )
        );
    end

    // DUT
    hyperbus #(
        .NumChips       ( NumChips    ),
        .AxiAddrWidth   ( AxiAw       ),
        .AxiDataWidth   ( AxiDw       ),
        .AxiIdWidth     ( AxiIw       ),
        .axi_req_t      ( req_t       ),
        .axi_rsp_t      ( resp_t      ),
        .RegAddrWidth   ( RegAw       ),
        .RegDataWidth   ( RegDw       ),
        .reg_req_t      ( reg_req_t   ),
        .reg_rsp_t      ( reg_rsp_t   ),
        .axi_rule_t     ( rule_t      )
    ) i_dut (
        .clk_phy_i              ( phy_clk               ),
        .clk_sys_i              ( sys_clk               ),
        .rst_ni                 ( rst_n                 ),
        .test_mode_i            ( test_mode             ),
        .axi_req_i              ( axi_master_req        ),
        .axi_rsp_o              ( axi_master_rsp        ),
        .reg_req_i              ( reg_req               ),
        .reg_rsp_o              ( reg_rsp               ),
        .hyper_cs_no            ( hyper_cs_n_wire       ),
        .hyper_ck_o             ( hyper_ck_wire         ),
        .hyper_ck_no            ( hyper_ck_n_wire       ),
        .hyper_rwds_o           ( hyper_rwds_o          ),
        .hyper_rwds_i           ( hyper_rwds_i          ),
        .hyper_rwds_oe_o        ( hyper_rwds_oe         ),
        .hyper_dq_i             ( hyper_dq_i            ),
        .hyper_dq_o             ( hyper_dq_o            ),
        .hyper_dq_oe_o          ( hyper_dq_oe           ),
        .hyper_reset_no         ( hyper_reset_n_wire    )
    );

    // modell
      s27ks0641 #(
        /*.mem_file_name ( "s27ks0641.mem"    ),*/
        .TimingModel   ( "S27KS0641DPBHI020"    )
    ) i_s27ks0641 (
      .DQ7           ( hyper_dq_wire[7]      ),
      .DQ6           ( hyper_dq_wire[6]      ),
      .DQ5           ( hyper_dq_wire[5]      ),
      .DQ4           ( hyper_dq_wire[4]      ),
      .DQ3           ( hyper_dq_wire[3]      ),
      .DQ2           ( hyper_dq_wire[2]      ),
      .DQ1           ( hyper_dq_wire[1]      ),
      .DQ0           ( hyper_dq_wire[0]      ),
      .RWDS          ( hyper_rwds_wire       ),
      .CSNeg         ( hyper_cs_n_wire[0]    ),
      .CK            ( hyper_ck_wire         ),
      .CKNeg         ( hyper_ck_n_wire       ),
      .RESETNeg      ( hyper_reset_n_wire    )
    );

    initial begin
        automatic string sdf_file_path = "models/s27ks0641/s27ks0641.sdf";
        $sdf_annotate(sdf_file_path, i_s27ks0641);
    end

    // -------------------------- TB TASKS --------------------------

    // Initial reset
    initial begin
        rst_n = 0;
        axi_master_drv.reset_master();
        // i_rmaster.reset_master();
        #(0.25*SYS_TCK);
        #(10*SYS_TCK);
        rst_n = 1;
    end

    // Generate clock
    initial begin
        while (!eos) begin
            sys_clk = 1;
            #(SYS_TCK/2);
            sys_clk = 0;
            #(SYS_TCK/2);
        end
        // Extra cycle after sim
        sys_clk = 1;
        #(SYS_TCK/2);
        sys_clk = 0;
        #(SYS_TCK/2);
    end

    // Generate clock
    initial begin
        while (!eos) begin
            phy_clk = 1;
            #(PHY_TCK/2);
            phy_clk = 0;
            #(PHY_TCK/2);
        end
        // Extra cycle after sim
        phy_clk = 1;
        #(PHY_TCK/2);
        phy_clk = 0;
        #(PHY_TCK/2);
    end

    task reset_end;
        @(posedge rst_n);
        @(posedge sys_clk);
    endtask

    // axi read task
    task read_axi;
        input axi_addr_t      raddr;
        input axi_pkg::len_t  burst_len;
        input axi_pkg::size_t size;

        @(posedge sys_clk);

        ar_beat.ax_addr  = raddr;
        ar_beat.ax_len   = burst_len;
        ar_beat.ax_burst = axi_pkg::BURST_INCR;
        ar_beat.ax_size  = size;

        axi_master_drv.send_ar(ar_beat);

        for(int unsigned i = 0; i < burst_len + 1; i++) begin
            axi_master_drv.recv_r(r_beat);
            $display("%p", r_beat);
            $display("%x", r_beat.r_data);
        end
    endtask

    // axi write task
    task write_axi;
        input axi_addr_t      waddr;
        input axi_pkg::len_t  burst_len;
        input axi_pkg::size_t size;
        input axi_data_t      wdata;
        input axi_strb_t      wstrb;

        @(posedge sys_clk);

        aw_beat.ax_addr  = waddr;
        aw_beat.ax_len   = burst_len;
        aw_beat.ax_burst = axi_pkg::BURST_INCR;
        aw_beat.ax_size  = size;
        w_beat.w_data   = wdata;
        w_beat.w_strb   = wstrb;
        w_beat.w_last   = 1'b0;

        axi_master_drv.send_aw(aw_beat);

        for(int unsigned i = 0; i < burst_len + 1; i++) begin
            if (i == burst_len) begin
                w_beat.w_last = 1'b1;
            end
            axi_master_drv.send_w(w_beat);
            $display("%p", w_beat);
            $display("%x", w_beat.w_data);
        end

        axi_master_drv.recv_b(b_beat);
        $display("%p", b_beat);

    endtask


endmodule : fixture_hyperbus


module tristate_shim (
    input  wire out_ena_i,
    input  wire out_i,
    output wire in_o,
    inout  wire line_io
);

    assign line_io = out_ena_i ? out_i : 1'bz;
    assign in_o    = out_ena_i ? 1'bx  : line_io;

endmodule : tristate_shim
