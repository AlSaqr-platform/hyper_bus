package hyperbus_pkg;

    // configuration type
  typedef struct packed {
    logic [3:0]   t_latency_access;
    logic         en_latency_additional;
    logic [15:0]  t_cs_max;
    logic [3:0]   t_read_write_recovery;
    logic [7:0]   t_rwds_delay_line;
    logic [1:0]   t_variable_latency_check;
  } hyperbus_cfg_t;

endpackage