// Hyperbus Fixture

// this code is unstable and most likely buggy
// it should not be used by anyone

/// Author: Thomas Benz <tbenz@iis.ee.ethz.ch>
`timescale 1 ns/1 ps

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "register_interface/typedef.svh"

module fixture_hyperbus import hyperbus_pkg::NumPhys; #(
    parameter int unsigned NumChips = 2
);

   
    int unsigned            k, j;
    localparam time SYS_TCK  = 2.78ns;
    localparam time SYS_TA   = 1ns;
    localparam time SYS_TT   = SYS_TCK - 1ns;

    localparam time PHY_TCK  = 10ns;

    logic sys_clk      = 0;
    logic phy_clk      = 0;
    logic phy_clk90    = 0;
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

    logic [127:0] trans_wdata;
    logic [127:0] trans_rdata;
    axi_addr_t    temp_waddr;
    axi_addr_t    temp_raddr;
    logic [4:0]   last_waddr;
    logic [4:0]   last_raddr;
    typedef logic [127:0] data_t;   
    data_t        memory[bit [31:0]];
    int           read_index = 0;
    int           write_index = 0;
   
   
    reg_req_t   reg_req;
    reg_rsp_t   reg_rsp;

    REG_BUS #(
        .ADDR_WIDTH( RegAw ),
        .DATA_WIDTH( RegDw )
    ) i_rbus (
        .clk_i (sys_clk)
    );
    integer fr, fw;

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
    wire  [NumPhys-1:0][1:0] hyper_cs_n_wire;
    wire  [NumPhys-1:0]      hyper_ck_wire;
    wire  [NumPhys-1:0]      hyper_ck_n_wire;
    wire  [NumPhys-1:0]      hyper_rwds_o;
    wire  [NumPhys-1:0]      hyper_rwds_i;
    wire  [NumPhys-1:0]      hyper_rwds_oe;
    wire  [NumPhys-1:0]      hyper_rwds_wire;
    wire  [NumPhys-1:0][7:0] hyper_dq_i;
    wire  [NumPhys-1:0][7:0] hyper_dq_o;
    wire  [NumPhys-1:0]      hyper_dq_oe;
    wire  [NumPhys-1:0][7:0] hyper_dq_wire;
    wire  [NumPhys-1:0]      hyper_reset_n_wire;
             

    generate
       for (genvar i=0; i<NumPhys; i++) begin : hyperrams
          tristate_shim i_tristate_shim_rwdsi (
              .out_ena_i  ( hyper_rwds_oe[i]   ),
              .out_i      ( hyper_rwds_o[i]    ),
              .in_o       ( hyper_rwds_i[i]    ),
              .line_io    ( hyper_rwds_wire[i] )
          );
          
          for (genvar m = 0; m < 8; m++) begin
              tristate_shim i_tristate_shim_dqi (
                  .out_ena_i  ( hyper_dq_oe[i]       ),
                  .out_i      ( hyper_dq_o[i]    [m] ),
                  .in_o       ( hyper_dq_i[i]    [m] ),
                  .line_io    ( hyper_dq_wire[i] [m] )
              );
          end

          s27ks0641 #(
            /*.mem_file_name ( "s27ks0641.mem"    ),*/
            .TimingModel   ( "S27KS0641DPBHI020"    )
          ) i_s27ks0641 (
            .DQ7           ( hyper_dq_wire[i][7]      ),
            .DQ6           ( hyper_dq_wire[i][6]      ),
            .DQ5           ( hyper_dq_wire[i][5]      ),
            .DQ4           ( hyper_dq_wire[i][4]      ),
            .DQ3           ( hyper_dq_wire[i][3]      ),
            .DQ2           ( hyper_dq_wire[i][2]      ),
            .DQ1           ( hyper_dq_wire[i][1]      ),
            .DQ0           ( hyper_dq_wire[i][0]      ),
            .RWDS          ( hyper_rwds_wire[i]       ),
            .CSNeg         ( hyper_cs_n_wire[i][0]    ),
            .CK            ( hyper_ck_wire[i]         ),
            .CKNeg         ( hyper_ck_n_wire[i]       ),
            .RESETNeg      ( hyper_reset_n_wire[i]    )
          );
       end // block: hyperrams
    endgenerate
 
   
    // DUT
    hyperbus #(
        .NumChips       ( NumChips    ),
        .AxiAddrWidth   ( AxiAw       ),
        .AxiDataWidth   ( AxiDw       ),
        .AxiIdWidth     ( AxiIw       ),
        .axi_req_t      ( req_t       ),
        .axi_rsp_t      ( resp_t      ),
        .axi_w_chan_t   ( w_chan_t    ),
        .RegAddrWidth   ( RegAw       ),
        .RegDataWidth   ( RegDw       ),
        .reg_req_t      ( reg_req_t   ),
        .reg_rsp_t      ( reg_rsp_t   ),
        .IsClockODelayed( 1           ),
        .axi_rule_t     ( rule_t      )
    ) i_dut (
        .clk_phy_i              ( phy_clk               ),
        .clk_phy_i_90           ( phy_clk90             ),
        .rst_phy_ni             ( rst_n                 ),
        .clk_sys_i              ( sys_clk               ),
        .rst_sys_ni             ( rst_n                 ),
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

    generate
       for (genvar p=0; p<NumPhys; p++) begin : sdf_annotation
         initial begin
             automatic string sdf_file_path = "/scratch/lvalente/hyperwork/cva6/hardware/working_dir/hyperbus/models/s27ks0641/s27ks0641.sdf";
             $sdf_annotate(sdf_file_path, hyperrams[p].i_s27ks0641);
             $display("NumPhys:%d",NumPhys);
         end
       end
    endgenerate
   

    // -------------------------- TB TASKS --------------------------

    // Initial reset
    initial begin
        rst_n = 0;
        axi_master_drv.reset_master();
        fr = $fopen ("axireadvalues.txt","w");
        fw = $fopen ("axiwrotevalues.txt","w");
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
 
   always @(phy_clk) phy_clk90 <= #(PHY_TCK/4) phy_clk;

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

        temp_raddr = raddr;
        last_raddr = '0;
              
        for(int unsigned i = 0; i < burst_len + 1; i++) begin
            axi_master_drv.recv_r(r_beat);
            $display("%p", r_beat);
            $display("%x", r_beat.r_data);
            trans_rdata = '0;
            if (i==0) begin
               for(k =temp_raddr[3:0]; k<((temp_raddr[3:0]>>size)<<size) + (2**size) ; k++) begin 
                 trans_rdata[k*8 +:8] = r_beat.r_data[(k*8) +: 8];
               end
            end else begin
               for(j=temp_raddr[3:0]; j<temp_raddr[3:0]+(2**size); j++) begin
                  trans_rdata[j*8 +:8] = r_beat.r_data[(j*8) +: 8];
               end
            end
            $fwrite(fr, "%x %x %d\n", trans_rdata, temp_raddr, (((temp_raddr[3:0]>>size)<<size) + (2**size)));
            if(memory[read_index]!=trans_rdata) begin
               $fatal(1,"Error @%x\n", temp_raddr);
            end            read_index++;
            if(i==0)
              temp_raddr = ((temp_raddr>>size)<<size) + (2**size);
            else
              temp_raddr = temp_raddr + (2**size);    
            last_raddr = temp_raddr[3:0] + (2**size);       
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

        temp_waddr = waddr;
        aw_beat.ax_addr  = waddr;
        aw_beat.ax_len   = burst_len;
        aw_beat.ax_burst = axi_pkg::BURST_INCR;
        aw_beat.ax_size  = size;
        w_beat.w_data   = wdata;
        w_beat.w_strb   = wstrb;
        w_beat.w_last   = 1'b0;
        last_waddr = '0;

        axi_master_drv.send_aw(aw_beat);

       
        for(int unsigned i = 0; i < burst_len + 1; i++) begin
            if (i == burst_len) begin
                w_beat.w_last = 1'b1;
            end
            axi_master_drv.send_w(w_beat);
            trans_wdata = '0;
            $display("%p", w_beat);
            $display("%x", w_beat.w_data);
            if (i==0) begin
               for (k = temp_waddr[3:0]; k<((temp_waddr[3:0]>>size)<<size) + (2**size) ; k++)  begin
                 trans_wdata[k*8 +:8] = (wstrb[k]) ? w_beat.w_data[(k*8) +: 8] : '0;
               end
            end else begin
               for(j=temp_waddr[3:0]; j<temp_waddr[3:0]+(2**size); j++) begin
                  trans_wdata[j*8 +:8] = (wstrb[j]) ? w_beat.w_data[(j*8) +: 8] : '0;
               end
            end
            $fwrite(fw, "%x %x %d\n",trans_wdata, temp_waddr, (((temp_waddr[3:0]>>size)<<size) + (2**size)));
            memory[write_index]=trans_wdata;
            write_index++;
            if(i==0)
              temp_waddr = ((temp_waddr>>size)<<size) + (2**size);
            else
              temp_waddr = temp_waddr + (2**size);
            last_waddr = temp_waddr[3:0] + (2**size);
        end // for (int unsigned i = 0; i < burst_len + 1; i++)

        axi_master_drv.recv_b(b_beat);
        //$display("%x", b_beat);
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
