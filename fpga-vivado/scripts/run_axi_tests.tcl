

## Automatic tests running on fpga by jtag-axi-bridge 
reset_hw_axi [get_hw_axis hw_axi_1]
create_hw_axi_txn wr0_16 [get_hw_axis hw_axi_1] -address 00000000 -data {0000FF00_0000DDEE_0000BBCC_000099AA_00007788_00005566_00003344_00001122_0000FF00_0000DDEE_0000BBCC_000099AA_00007788_00005566_00003344_00001122} -len 16 -type write
create_hw_axi_txn rd0_16 [get_hw_axis hw_axi_1] -address 00000000 -len 16 -type read
create_hw_axi_txn rd2_8  [get_hw_axis hw_axi_1] -address 00000002 -len 8 -type read
create_hw_axi_txn rd_last  [get_hw_axis hw_axi_1] -address 00001FFC -len 8 -type read
create_hw_axi_txn rd_id_0  [get_hw_axis hw_axi_1] -address 80000000 -len 1 -type read
create_hw_axi_txn rd_id_1  [get_hw_axis hw_axi_1] -address 80000001 -len 1 -type read
create_hw_axi_txn wr_config_latency [get_hw_axis hw_axi_1] -address 80000800 -data {00008f17} -len 1 -type write
create_hw_axi_txn wr_config_3cycles [get_hw_axis hw_axi_1] -address 80000800 -data {00008fef} -len 1 -type write
create_hw_axi_txn wr_config_3cl [get_hw_axis hw_axi_1] -address 80000800 -data {00008fe7} -len 1 -type write
create_hw_axi_txn rd_config_0 [get_hw_axis hw_axi_1] -address 80000800 -data {00008f17} -len 1 -type read
create_hw_axi_txn rd_config_1 [get_hw_axis hw_axi_1] -address 80000801 -data {00008f17} -len 1 -type read

create_hw_axi_txn wr2_16 [get_hw_axis hw_axi_1] -address 00000002 -data {0000FF00_0000DDEE_0000BBCC_000099AA_00007788_00005566_00003344_00001122_0000FF00_0000DDEE_0000BBCC_000099AA_00007788_00005566_00003344_00001122} -len 16 -type write


run_hw_axi wr2_16

run_hw_axi rd0_16
set result [get_property DATA [get_hw_axi_txns  rd0_16]]
set expected_result 0000ff000000ddee0000bbcc000099aa000077880000556600003344000011220000ff000000ddee0000bbcc000099aa00007788000055660000334400001122
if {![expr {$result eq $expected_result}]} {error "received unexpected results: $result"}

run_hw_axi rd2_8
set result [get_property DATA [get_hw_axi_txns  rd2_8]]
set expected_result 00003344000011220000ff000000ddee0000bbcc000099aa0000778800005566
if {![expr {$result eq $expected_result}]} {error "received unexpected results"}

run_hw_axi rd_id_0
set result [get_property DATA [get_hw_axi_txns  rd_id_0]]
set expected_result 00000c81
if {![expr {$result eq $expected_result}]} {error "received unexpected results"}
