

# # hyper signals (cs reset)
editPin -fixedPin 1 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 2134.588 99.365 -end 2140.487 99.553 \
        -pin {{hyper_cs_no[0]} {hyper_cs_no[1]} hyper_reset_no}

editPin -fixedPin 1 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1200.365 100 -end 1250 99.553 \
        -pin {cfg_i_ready axi_i_b_user[0] axi_i_r_user[0]}


# Allow connection to chip only on top of macro
createPinGroup inChip -cell hyperbus_macro_inflate -optimizeOrder
addPinToPinGroup -pinGroup inChip -cell hyperbus_macro_inflate -pin axi*
addPinToPinGroup -pinGroup inChip -cell hyperbus_macro_inflate -pin cfg*
addPinToPinGroup -pinGroup inChip -cell hyperbus_macro_inflate -pin clk*
addPinToPinGroup -pinGroup inChip -cell hyperbus_macro_inflate -pin hyper_reset*
addPinToPinGroup -pinGroup inChip -cell hyperbus_macro_inflate -pin debug_*
createPinGuide -name inChip -cell hyperbus_macro_inflate -edge 1 -layer {M2 M4 M6}



# setPinAssignMode -pinEditInBatch true
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1565.739 99.9 -end 1607.045 99.9 -pin {{axi_i_r_data[0]} {axi_i_r_data[1]} {axi_i_r_data[2]} {axi_i_r_data[3]} {axi_i_r_data[4]} {axi_i_r_data[5]} {axi_i_r_data[6]} {axi_i_r_data[7]} {axi_i_r_data[8]} {axi_i_r_data[9]} {axi_i_r_data[10]} {axi_i_r_data[11]} {axi_i_r_data[12]} {axi_i_r_data[13]} {axi_i_r_data[14]} {axi_i_r_data[15]}}
# pan -9.691 1.509

# # id in
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1319.135 100.043 -end 1337.041 100.008 -pin {{axi_i_ar_id[0]} {axi_i_ar_id[1]} {axi_i_ar_id[2]} {axi_i_ar_id[3]} {axi_i_ar_id[4]} {axi_i_ar_id[5]} {axi_i_ar_id[6]} {axi_i_ar_id[7]} {axi_i_ar_id[8]} {axi_i_ar_id[9]} {axi_i_aw_id[0]} {axi_i_aw_id[1]} {axi_i_aw_id[2]} {axi_i_aw_id[3]} {axi_i_aw_id[4]} {axi_i_aw_id[5]} {axi_i_aw_id[6]} {axi_i_aw_id[7]} {axi_i_aw_id[8]} {axi_i_aw_id[9]}}

# #id out
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 4 -spreadType range -start 1320.5 100.0 -end 1337.5 100.0 -pin {{axi_i_b_id[0]} {axi_i_b_id[1]} {axi_i_b_id[2]} {axi_i_b_id[3]} {axi_i_b_id[4]} {axi_i_b_id[5]} {axi_i_b_id[6]} {axi_i_b_id[7]} {axi_i_b_id[8]} {axi_i_b_id[9]} {axi_i_r_id[0]} {axi_i_r_id[1]} {axi_i_r_id[2]} {axi_i_r_id[3]} {axi_i_r_id[4]} {axi_i_r_id[5]} {axi_i_r_id[6]} {axi_i_r_id[7]} {axi_i_r_id[8]} {axi_i_r_id[9]}}

# #w data
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1280.381 99.946 -end 1289.773 99.821 -pin {{axi_i_w_data[0]} {axi_i_w_data[1]} {axi_i_w_data[2]} {axi_i_w_data[3]} {axi_i_w_data[4]} {axi_i_w_data[5]} {axi_i_w_data[6]} {axi_i_w_data[7]} {axi_i_w_data[8]} {axi_i_w_data[9]} {axi_i_w_data[10]} {axi_i_w_data[11]} {axi_i_w_data[12]} {axi_i_w_data[13]} {axi_i_w_data[14]} {axi_i_w_data[15]}}

# # a len
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1290.431 99.891 -end 1300.091 99.926 -pin {{axi_i_ar_len[0]} {axi_i_ar_len[1]} {axi_i_ar_len[2]} {axi_i_ar_len[3]} {axi_i_ar_len[4]} {axi_i_ar_len[5]} {axi_i_ar_len[6]} {axi_i_ar_len[7]} {axi_i_aw_len[0]} {axi_i_aw_len[1]} {axi_i_aw_len[2]} {axi_i_aw_len[3]} {axi_i_aw_len[4]} {axi_i_aw_len[5]} {axi_i_aw_len[6]} {axi_i_aw_len[7]}}

# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1264.874 99.814 -end 1279.55 99.964 -pin {{axi_i_ar_addr[0]} {axi_i_ar_addr[1]} {axi_i_ar_addr[2]} {axi_i_ar_addr[3]} {axi_i_ar_addr[4]} {axi_i_ar_addr[5]} {axi_i_ar_addr[6]} {axi_i_ar_addr[7]} {axi_i_ar_addr[8]} {axi_i_ar_addr[9]} {axi_i_ar_addr[10]} {axi_i_ar_addr[11]} {axi_i_ar_addr[12]} {axi_i_ar_addr[13]} {axi_i_ar_addr[14]} {axi_i_ar_addr[15]} {axi_i_ar_addr[16]} {axi_i_ar_addr[17]} {axi_i_ar_addr[18]} {axi_i_ar_addr[19]} {axi_i_ar_addr[20]} {axi_i_ar_addr[21]} {axi_i_ar_addr[22]} {axi_i_ar_addr[23]} {axi_i_ar_addr[24]} {axi_i_ar_addr[25]} {axi_i_ar_addr[26]} {axi_i_ar_addr[27]} {axi_i_ar_addr[28]} {axi_i_ar_addr[29]} {axi_i_ar_addr[30]} {axi_i_ar_addr[31]}}

# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 4 -spreadType range -start 1264.874 100.0 -end 1279.55 100.0 -pin {{axi_i_aw_addr[0]} {axi_i_aw_addr[1]} {axi_i_aw_addr[2]} {axi_i_aw_addr[3]} {axi_i_aw_addr[4]} {axi_i_aw_addr[5]} {axi_i_aw_addr[6]} {axi_i_aw_addr[7]} {axi_i_aw_addr[8]} {axi_i_aw_addr[9]} {axi_i_aw_addr[10]} {axi_i_aw_addr[11]} {axi_i_aw_addr[12]} {axi_i_aw_addr[13]} {axi_i_aw_addr[14]} {axi_i_aw_addr[15]} {axi_i_aw_addr[16]} {axi_i_aw_addr[17]} {axi_i_aw_addr[18]} {axi_i_aw_addr[19]} {axi_i_aw_addr[20]} {axi_i_aw_addr[21]} {axi_i_aw_addr[22]} {axi_i_aw_addr[23]} {axi_i_aw_addr[24]} {axi_i_aw_addr[25]} {axi_i_aw_addr[26]} {axi_i_aw_addr[27]} {axi_i_aw_addr[28]} {axi_i_aw_addr[29]} {axi_i_aw_addr[30]} {axi_i_aw_addr[31]}}

# editPin -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1149.564 99.935 -end 1218.074 99.458 -pin {{cfg_i_addr[0]} {cfg_i_addr[1]} {cfg_i_addr[2]} {cfg_i_addr[3]} {cfg_i_addr[4]} {cfg_i_addr[5]} {cfg_i_addr[6]} {cfg_i_addr[7]} {cfg_i_addr[8]} {cfg_i_addr[9]} {cfg_i_addr[10]} {cfg_i_addr[11]} {cfg_i_addr[12]} {cfg_i_addr[13]} {cfg_i_addr[14]} {cfg_i_addr[15]} {cfg_i_addr[16]} {cfg_i_addr[17]} {cfg_i_addr[18]} {cfg_i_addr[19]} {cfg_i_addr[20]} {cfg_i_addr[21]} {cfg_i_addr[22]} {cfg_i_addr[23]} {cfg_i_addr[24]} {cfg_i_addr[25]} {cfg_i_addr[26]} {cfg_i_addr[27]} {cfg_i_addr[28]} {cfg_i_addr[29]} {cfg_i_addr[30]} {cfg_i_addr[31]} cfg_i_error {cfg_i_rdata[0]} {cfg_i_rdata[1]} {cfg_i_rdata[2]} {cfg_i_rdata[3]} {cfg_i_rdata[4]} {cfg_i_rdata[5]} {cfg_i_rdata[6]} {cfg_i_rdata[7]} {cfg_i_rdata[8]} {cfg_i_rdata[9]} {cfg_i_rdata[10]} {cfg_i_rdata[11]} {cfg_i_rdata[12]} {cfg_i_rdata[13]} {cfg_i_rdata[14]} {cfg_i_rdata[15]} {cfg_i_rdata[16]} {cfg_i_rdata[17]} {cfg_i_rdata[18]} {cfg_i_rdata[19]} {cfg_i_rdata[20]} {cfg_i_rdata[21]} {cfg_i_rdata[22]} {cfg_i_rdata[23]} {cfg_i_rdata[24]} {cfg_i_rdata[25]} {cfg_i_rdata[26]} {cfg_i_rdata[27]} {cfg_i_rdata[28]} {cfg_i_rdata[29]} {cfg_i_rdata[30]} {cfg_i_rdata[31]} cfg_i_ready cfg_i_valid {cfg_i_wdata[0]} {cfg_i_wdata[1]} {cfg_i_wdata[2]} {cfg_i_wdata[3]} {cfg_i_wdata[4]} {cfg_i_wdata[5]} {cfg_i_wdata[6]} {cfg_i_wdata[7]} {cfg_i_wdata[8]} {cfg_i_wdata[9]} {cfg_i_wdata[10]} {cfg_i_wdata[11]} {cfg_i_wdata[12]} {cfg_i_wdata[13]} {cfg_i_wdata[14]} {cfg_i_wdata[15]} {cfg_i_wdata[16]} {cfg_i_wdata[17]} {cfg_i_wdata[18]} {cfg_i_wdata[19]} {cfg_i_wdata[20]} {cfg_i_wdata[21]} {cfg_i_wdata[22]} {cfg_i_wdata[23]} {cfg_i_wdata[24]} {cfg_i_wdata[25]} {cfg_i_wdata[26]} {cfg_i_wdata[27]} {cfg_i_wdata[28]} {cfg_i_wdata[29]} {cfg_i_wdata[30]} {cfg_i_wdata[31]} cfg_i_write {cfg_i_wstrb[0]} {cfg_i_wstrb[1]} {cfg_i_wstrb[2]} {cfg_i_wstrb[3]}}

# # b channel
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1340.775 99.826 -end 1345.982 99.826 -pin {axi_i_b_ready {axi_i_b_resp[0]} {axi_i_b_resp[1]} {axi_i_b_user[0]} axi_i_b_valid}


# # ready valid
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1305.718 99.848 -end 1310.619 99.931 -pin {axi_i_ar_valid axi_i_aw_ready axi_i_ar_ready axi_i_aw_valid axi_i_w_ready axi_i_w_valid}


# # r channel
# editPin -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1392.2 100.1 -end 1474.4 100.1 -pin {{axi_i_r_resp[0]} {axi_i_r_resp[1]} {axi_i_r_user[0]} axi_i_r_last axi_i_r_ready axi_i_r_valid}

# # w channel
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1301.098 99.85 -end 1304.16 99.88 -pin {axi_i_w_last {axi_i_w_strb[0]} {axi_i_w_strb[1]} {axi_i_w_user[0]}}




# # clk rst
# editPin -pinWidth 0.1 -pinDepth 0.52 -fixOverlap 1 -spreadDirection clockwise -side Top -layer 2 -spreadType range -start 1255.854 100.021 -end 1258.327 100.021 -pin {rst_ni clk_sys_i clk_phy_i}
