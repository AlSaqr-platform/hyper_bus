// Hyperbus Fixture

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"

module fixture_hyperbus;

    localparam TCK  = 1ns;
    localparam TA   = 0.01 * TCK;
    localparam TT   = 0.99 * TCK;

    logic clk   = 0;
    logic rst_n = 1;
    logic eos   = 0; // end of sim

    // -------------------- AXI drivers --------------------

    parameter AXI_AW = 32;
    parameter AXI_DW = 64;
    parameter AXI_IW = 6;

    typedef logic [AXI_AW-1:0]   axi_addr_t;
    typedef logic [AXI_DW-1:0]   axi_data_t;
    typedef logic [AXI_DW/8-1:0] axi_strb_t;
    typedef logic [AXI_IW-1:0]   axi_id_t;

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
        .AXI_ADDR_WIDTH(AXI_AW),
        .AXI_DATA_WIDTH(AXI_DW),
        .AXI_ID_WIDTH  (AXI_IW),
        .AXI_USER_WIDTH(1     )
    ) axi_dv(clk);

    AXI_BUS #(
        .AXI_ADDR_WIDTH(AXI_AW),
        .AXI_DATA_WIDTH(AXI_DW),
        .AXI_ID_WIDTH  (AXI_IW),
        .AXI_USER_WIDTH(1     )
    ) axi_master();

    `AXI_ASSIGN(axi_master, axi_dv)

    `AXI_ASSIGN_TO_REQ(axi_master_req, axi_master)
    `AXI_ASSIGN_FROM_RESP(axi_master, axi_master_rsp)

    axi_test::axi_driver #(.AW(AXI_AW), .DW(AXI_DW), .IW(AXI_IW), .UW(1), .TA(TA), .TT(TT)) axi_master_drv = new(axi_dv);

    // -------------------------- TB TASKS --------------------------
    // Initial reset
    initial begin
        rst_n = 0;
        axi_master_drv.reset_master();
        #(0.25*TCK);
        #(10*TCK);
        rst_n = 1;
    end

    // Generate clock
    initial begin
        while (!eos) begin
            clk = 1;
            #(TCK/2);
            clk = 0;
            #(TCK/2);
        end
        // Extra cycle after sim
        clk = 1;
        #(TCK/2);
        clk = 0;
        #(TCK/2);
    end

    task reset_end;
        @(negedge rst_n);
        @(posedge clk);
    endtask

    // axi read task
    task read_axi;
        input axi_addr_t     raddr;
        input axi_pkg::len_t burst_len;
        automatic axi_test::axi_ax_beat #(.AW(AXI_AW), .IW(AXI_IW), .UW(1)) ar_beat = new();
        automatic axi_test::axi_r_beat  #(.DW(AXI_DW), .IW(AXI_IW), .UW(1)) r_beat  = new();

        @(posedge clk);

        ar_beat.ax_addr = raddr;
        ar_beat.ax_len  = burst_len;

        axi_master_drv.send_ar(ar_beat);

        for(int unsigned i = 0; i < burst_len; i++) begin
            axi_master_drv.recv_r(r_beat);
            $display("%p", r_beat);
        end
    endtask

    // axi write task
    task write_axi;
        input axi_addr_t     waddr;
        input axi_pkg::len_t burst_len;
        input axi_data_t     wdata;
        input axi_strb_t     wstrb;
        automatic axi_test::axi_ax_beat #(.AW(AXI_AW), .IW(AXI_IW), .UW(1)) aw_beat = new();
        automatic axi_test::axi_r_beat  #(.DW(AXI_DW), .IW(AXI_IW), .UW(1)) w_beat  = new();
        automatic axi_test::axi_r_beat  #(.DW(AXI_DW), .IW(AXI_IW), .UW(1)) b_beat  = new();

        @(posedge clk);

        aw_beat.ax_addr = waddr;
        aw_beat.ax_len  = burst_len;

        w_beat.w_data   = wdata;
        w_beat.w_strb   = wstrb;

        axi_master_drv.send_ar(aw_beat);

        for(int unsigned i = 0; i < burst_len; i++) begin
            axi_master_drv.send_w(w_beat);
            $display("%p", w_beat);
        end

        axi_master_drv.recv_b(b_beat);
        $display("%p", b_beat);

    endtask


endmodule : fixture_hyperbus
