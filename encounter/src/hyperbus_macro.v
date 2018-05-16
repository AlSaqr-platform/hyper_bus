module hyperbus_macro (
  clk_i,
  rst_ni,
  axi_i_ar_addr,
  axi_i_ar_burst,
  axi_i_ar_cache,
  axi_i_ar_id,
  axi_i_ar_len,
  axi_i_ar_lock,
  axi_i_ar_prot,
  axi_i_ar_qos,
  axi_i_ar_ready,
  axi_i_ar_region,
  axi_i_ar_size,
  axi_i_ar_user,
  axi_i_ar_valid,
  axi_i_aw_addr,
  axi_i_aw_burst,
  axi_i_aw_cache,
  axi_i_aw_id,
  axi_i_aw_len,
  axi_i_aw_lock,
  axi_i_aw_prot,
  axi_i_aw_qos,
  axi_i_aw_ready,
  axi_i_aw_region,
  axi_i_aw_size,
  axi_i_aw_user,
  axi_i_aw_valid,
  axi_i_b_id,
  axi_i_b_ready,
  axi_i_b_resp,
  axi_i_b_user,
  axi_i_b_valid,
  axi_i_r_data,
  axi_i_r_id,
  axi_i_r_last,
  axi_i_r_ready,
  axi_i_r_resp,
  axi_i_r_user,
  axi_i_r_valid,
  axi_i_w_data,
  axi_i_w_last,
  axi_i_w_ready,
  axi_i_w_strb,
  axi_i_w_user,
  axi_i_w_valid,
  hyper_ck_no,
  hyper_ck_o,
  hyper_cs_no,
  hyper_dq_io,
  hyper_reset_no,
  hyper_rwds_io
);

  input [9:0] axi_i_aw_id;
  input [31:0] axi_i_aw_addr;
  input [7:0] axi_i_aw_len;
  input [2:0] axi_i_aw_size;
  input [1:0] axi_i_aw_burst;
  input [3:0] axi_i_aw_cache;
  input [2:0] axi_i_aw_prot;
  input [3:0] axi_i_aw_qos;
  input [3:0] axi_i_aw_region;
  input [-1:0] axi_i_aw_user;
  input [15:0] axi_i_w_data;
  input [1:0] axi_i_w_strb;
  input [-1:0] axi_i_w_user;
  output [9:0] axi_i_b_id;
  output [1:0] axi_i_b_resp;
  output [-1:0] axi_i_b_user;
  input [9:0] axi_i_ar_id;
  input [31:0] axi_i_ar_addr;
  input [7:0] axi_i_ar_len;
  input [2:0] axi_i_ar_size;
  input [1:0] axi_i_ar_burst;
  input [3:0] axi_i_ar_cache;
  input [2:0] axi_i_ar_prot;
  input [3:0] axi_i_ar_qos;
  input [3:0] axi_i_ar_region;
  input [-1:0] axi_i_ar_user;
  output [9:0] axi_i_r_id;
  output [15:0] axi_i_r_data;
  output [1:0] axi_i_r_resp;
  output [-1:0] axi_i_r_user;
  
  input clk_i, rst_ni, axi_i_aw_lock, axi_i_aw_valid, axi_i_w_last,
         axi_i_w_valid, axi_i_b_ready, axi_i_ar_lock, axi_i_ar_valid,
         axi_i_r_ready;
  output axi_i_aw_ready, axi_i_w_ready, axi_i_b_valid, axi_i_ar_ready,
         axi_i_r_last, axi_i_r_valid;
         
  output [1:0] hyper_cs_no;
  inout  [7:0] hyper_dq_io;
  inout  hyper_rwds_io;
  output hyper_ck_o;
  output hyper_ck_no;
  output hyper_reset_no;

  wire [7:0] hyper_dq_i_inner;
  wire [7:0] hyper_dq_o_inner;
  wire hyper_rwds_i_inner;
  wire hyper_ck_o_inner;
  wire hyper_ck_no_inner;
  wire hyper_rwds_o_inner;
  wire hyper_rwds_oe_o_inner;
  wire hyper_dq_oe_o_inner;
  wire hyper_reset_no_inner;

  hyperbus_inflate i_hyperbus (
    .clk_i(clk_i), 
    .rst_ni(rst_ni),
    .axi_i_ar_addr(axi_i_ar_addr), 
    .axi_i_ar_burst(axi_i_ar_burst), 
    .axi_i_ar_cache(axi_i_ar_cache), 
    .axi_i_ar_id(axi_i_ar_id), 
    .axi_i_ar_len(axi_i_ar_len), 
    .axi_i_ar_lock(axi_i_ar_lock), 
    .axi_i_ar_prot(axi_i_ar_prot), 
    .axi_i_ar_qos(axi_i_ar_qos), 
    .axi_i_ar_ready(axi_i_ar_ready), 
    .axi_i_ar_region(axi_i_ar_region), 
    .axi_i_ar_size(axi_i_ar_size), 
    .axi_i_ar_user(axi_i_ar_user), 
    .axi_i_ar_valid(axi_i_ar_valid), 
    .axi_i_aw_addr(axi_i_aw_addr), 
    .axi_i_aw_burst(axi_i_aw_burst), 
    .axi_i_aw_cache(axi_i_aw_cache), 
    .axi_i_aw_id(axi_i_aw_id), 
    .axi_i_aw_len(axi_i_aw_len), 
    .axi_i_aw_lock(axi_i_aw_lock), 
    .axi_i_aw_prot(axi_i_aw_prot), 
    .axi_i_aw_qos(axi_i_aw_qos), 
    .axi_i_aw_ready(axi_i_aw_ready), 
    .axi_i_aw_region(axi_i_aw_region), 
    .axi_i_aw_size(axi_i_aw_size), 
    .axi_i_aw_user(axi_i_aw_user), 
    .axi_i_aw_valid(axi_i_aw_valid), 
    .axi_i_b_id(axi_i_b_id), 
    .axi_i_b_ready(axi_i_b_ready), 
    .axi_i_b_resp(axi_i_b_resp), 
    .axi_i_b_user(axi_i_b_user), 
    .axi_i_b_valid(axi_i_b_valid), 
    .axi_i_r_data(axi_i_r_data), 
    .axi_i_r_id(axi_i_r_id), 
    .axi_i_r_last(axi_i_r_last), 
    .axi_i_r_ready(axi_i_r_ready), 
    .axi_i_r_resp(axi_i_r_resp), 
    .axi_i_r_user(axi_i_r_user), 
    .axi_i_r_valid(axi_i_r_valid), 
    .axi_i_w_data(axi_i_w_data), 
    .axi_i_w_last(axi_i_w_last), 
    .axi_i_w_ready(axi_i_w_ready), 
    .axi_i_w_strb(axi_i_w_strb), 
    .axi_i_w_user(axi_i_w_user), 
    .axi_i_w_valid(axi_i_w_valid), 
    .hyper_ck_no(hyper_ck_no_inner), 
    .hyper_ck_o(hyper_ck_o_inner), 
    .hyper_cs_no(hyper_cs_no), 
    .hyper_dq_i(hyper_dq_i_inner), 
    .hyper_dq_o(hyper_dq_o_inner), 
    .hyper_dq_oe_o(hyper_dq_oe_o_inner), 
    .hyper_reset_no(hyper_reset_no),
    .hyper_rwds_i(hyper_rwds_i_inner), 
    .hyper_rwds_o(hyper_rwds_o_inner), 
    .hyper_rwds_oe_o(hyper_rwds_oe_o_inner) 
  );

  IUMB pad_hyper_ck_no (
    .DO(hyper_ck_no_inner),
    .DI(),
    .PAD(hyper_ck_no),
    .OE(1'b1),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_ck_o (
    .DO(hyper_ck_o_inner),
    .DI(),
    .PAD(hyper_ck_o),
    .OE(1'b1),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_rwds_io (
    .DO(hyper_rwds_o_inner),
    .DI(hyper_rwds_i_inner),
    .PAD(hyper_rwds_io),
    .OE(hyper_rwds_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_0 (
    .DO(hyper_dq_o_inner[0]),
    .DI(hyper_dq_i_inner[0]),
    .PAD(hyper_dq_io[0]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_1 (
    .DO(hyper_dq_o_inner[1]),
    .DI(hyper_dq_i_inner[1]),
    .PAD(hyper_dq_io[1]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_2 (
    .DO(hyper_dq_o_inner[2]),
    .DI(hyper_dq_i_inner[2]),
    .PAD(hyper_dq_io[2]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_3 (
    .DO(hyper_dq_o_inner[3]),
    .DI(hyper_dq_i_inner[3]),
    .PAD(hyper_dq_io[3]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_4 (
    .DO(hyper_dq_o_inner[4]),
    .DI(hyper_dq_i_inner[4]),
    .PAD(hyper_dq_io[4]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_5 (
    .DO(hyper_dq_o_inner[5]),
    .DI(hyper_dq_i_inner[5]),
    .PAD(hyper_dq_io[5]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_6 (
    .DO(hyper_dq_o_inner[6]),
    .DI(hyper_dq_i_inner[6]),
    .PAD(hyper_dq_io[6]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IUMB pad_hyper_dq_io_7 (
    .DO(hyper_dq_o_inner[7]),
    .DI(hyper_dq_i_inner[7]),
    .PAD(hyper_dq_io[7]),
    .OE(hyper_dq_oe_o_inner),
    .IDDQ(1'b0),
    .PIN2(1'b0),
    .PIN1(1'b0),
    .SMT(1'b0),
    .PD(1'b0),
    .PU(1'b0),
    .SR(1'b0)
  );

  IVSS    pad_vss_c ( );
  IVSSIO  pad_vss_p ( ); 

  IVDD    pad_vdd_c ( );
  IVDDIO  pad_vdd_p ( );

  IFILLER5 filler5_left ();
  IFILLER5 filler5_right ();

endmodule
