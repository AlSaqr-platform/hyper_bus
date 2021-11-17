package hyperbus_pkg;

    // Maximal burst size: 2^8 1024-bit words as 16-bit words (plus one as not decremented)
    localparam unsigned HyperBurstWidth = 8 + $clog2(1024/16) + 1;
    typedef logic [HyperBurstWidth-1:0] hyper_blen_t;

    // configuration type
    typedef struct packed {
        logic [3:0]     t_latency_access;
        logic           en_latency_additional;
        logic [15:0]    t_burst_max;
        logic [3:0]     t_read_write_recovery;
        logic [3:0]     t_rx_clk_delay;
        logic [3:0]     t_tx_clk_delay;
        logic [4:0]     address_mask_msb;
        logic           address_space;
    } hyper_cfg_t;

    typedef struct packed {
        logic [31:0]    data;
        logic           last;
        logic [3:0]     strb;   // mask data
    } hyper_tx_t;

    typedef struct packed {
        logic [31:0]    data;
        logic           last;
        logic           error;
    } hyper_rx_t;

    typedef struct packed {
        logic           write;     // transaction is a write
        hyper_blen_t    burst;
        logic           burst_type;
        logic           address_space;
        logic [31:0]    address;
    } hyper_tf_t;

    typedef enum logic[3:0] {
        Startup,
        Idle,
        SendCA,
        WaitLatAccess,
        Read,
        Write,
        WaitXfer,
        WaitRWR
    } hyper_phy_state_t;

    typedef struct packed {
        logic           write;
        logic           addr_space;
        logic           burst_type;
        logic [28:0]    addr_upper;
        logic [12:0]    reserved;
        logic [2:0]     addr_lower;
    } hyper_phy_ca_t;

   
	  typedef struct packed {
	  	logic cs0n_o;
	  	logic cs1n_o;
	  	logic ck_o;
	  	logic ckn_o;
	  	logic rwds_o;
	  	logic rwds_oe_o;
	  	logic resetn_o;
	  	logic dq0_o;
	  	logic dq1_o;
	  	logic dq2_o;
	  	logic dq3_o;
	  	logic dq4_o;
	  	logic dq5_o;
	  	logic dq6_o;
	  	logic dq7_o;
	  	logic dq_oe_o;
	  } hyper_to_pad_t;
    
	  typedef struct packed {
	  	logic rwds_i;
	  	logic dq0_i;
	  	logic dq1_i;
	  	logic dq2_i;
	  	logic dq3_i;
	  	logic dq4_i;
	  	logic dq5_i;
	  	logic dq6_i;
	  	logic dq7_i;
	  } pad_to_hyper_t;

endpackage
