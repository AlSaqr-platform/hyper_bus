package hyperbus_pkg;

    // configuration type
    typedef struct packed {
        logic [3:0]     t_latency_access;
        logic           en_latency_additional;
        logic [15:0]    t_cs_max;
        logic [3:0]     t_read_write_recovery;
        logic [7:0]     t_rwds_delay_line;
        logic [1:0]     t_variable_latency_check;
    } hyper_cfg_t;


    typedef struct packed {
        logic [15:0]    data;
        logic           last;
        logic [1:0]     strb;   // mask data
    } hyper_tx_t;

    typedef struct packed {
        logic [15:0]    data;
        logic           last;
        logic           error;
    } hyper_rx_t;

    typedef struct packed {
        logic           write;     // transaction is a write
        axi_pkg::len_t  burst;
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

endpackage
