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
        logic [1:0]     strb;   // mask data
    } hyper_tx_t;

    typedef struct packed {
        logic           last;
        logic           error;
        logic [15:0]    data;
    } hyper_rx_t;

    typedef struct packed {
        logic           last;
        logic           error;
    } hyper_b_t;

    typedef struct packed {
        logic           write;     // transaction is a write
        axi_pkg::len_t  burst;
        logic           burst_type;
        logic           address_space;
        logic [31:0]    address;
    } hyper_tf_t;

    typedef enum logic[3:0] {
        STANDBY,
        SET_CMD_ADDR, 
        CMD_ADDR, 
        REG_WRITE, 
        WAIT2, 
        WAIT, 
        DATA_W, 
        DATA_R, 
        WAIT_R, 
        WAIT_W, 
        ERROR, 
        END_R, 
        END,
        WAIT_FOR_B
    } hyper_trans_t;

endpackage
