
#tcheck_status /hyperbus_tb/dut_i/i_inflate/i_deflate/i_hyperbus/i_cdc_2phase_trans_signals/i_dst/req_dst_q_reg


tcheck_set /hyperbus_tb/dut_i/i_inflate/i_deflate/i_hyperbus/i_cdc_2phase_trans_signals/i_dst/req_dst_q_reg \
	"( SETUP (COND (ENABLE_RB === 1) (posedge  D) ) (COND (ENABLE_RB === 1) (posedge  CK)) )" OFF
tcheck_set /hyperbus_tb/dut_i/i_inflate/i_deflate/i_hyperbus/i_cdc_2phase_trans_signals/i_dst/req_dst_q_reg \
	"( SETUP (COND (ENABLE_RB === 1) (negedge  D) ) (COND (ENABLE_RB === 1) (posedge  CK)) )" OFF
