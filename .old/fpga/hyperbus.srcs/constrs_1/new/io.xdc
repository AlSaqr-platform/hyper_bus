#USER_SI570 300 MHz
set_property IOSTANDARD DIFF_SSTL12 [get_ports user_si570_sysclk_clk_n]
set_property PACKAGE_PIN AL8 [get_ports user_si570_sysclk_clk_p]
set_property PACKAGE_PIN AL7 [get_ports user_si570_sysclk_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports user_si570_sysclk_clk_p]

set_property PACKAGE_PIN AM13      [get_ports "reset"]   
set_property IOSTANDARD  LVCMOS33  [get_ports "reset"]

#LEDs
#set_property PACKAGE_PIN AG14      [get_ports "led_pins[0]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[0]"]
#set_property PACKAGE_PIN AF13      [get_ports "led_pins[1]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[1]"]
#set_property PACKAGE_PIN AE13      [get_ports "led_pins[2]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[2]"]
#set_property PACKAGE_PIN AJ14      [get_ports "led_pins[3]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[3]"]
#set_property PACKAGE_PIN AJ15      [get_ports "led_pins[4]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[4]"]
#set_property PACKAGE_PIN AH13      [get_ports "led_pins[5]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[5]"]
#set_property PACKAGE_PIN AH14      [get_ports "led_pins[6]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[6]"]
#set_property PACKAGE_PIN AL12      [get_ports "led_pins[7]"]
#set_property IOSTANDARD  LVCMOS33  [get_ports "led_pins[7]"]

##switch cs0 and cs1 to select ram for tests
set_property PACKAGE_PIN M14      [get_ports {hyper_cs_no[0]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_cs_no[0]}]
set_property PACKAGE_PIN M15      [get_ports {hyper_cs_no[1]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_cs_no[1]}]
set_property PACKAGE_PIN AB4           [get_ports hyper_ck_o]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports hyper_ck_o]
set_property PACKAGE_PIN AC4           [get_ports hyper_ck_no]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports hyper_ck_no]
set_property PACKAGE_PIN AB8      [get_ports hyper_rwds_io]
set_property IOSTANDARD HSTL_I_18 [get_ports hyper_rwds_io]
set_property PACKAGE_PIN AB3      [get_ports {hyper_dq_io[0]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[0]}]
set_property PACKAGE_PIN AC3      [get_ports {hyper_dq_io[1]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[1]}]
set_property PACKAGE_PIN W2       [get_ports {hyper_dq_io[2]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[2]}]
set_property PACKAGE_PIN W1       [get_ports {hyper_dq_io[3]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[3]}]
set_property PACKAGE_PIN Y12      [get_ports {hyper_dq_io[4]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[4]}]
set_property PACKAGE_PIN AA12     [get_ports {hyper_dq_io[5]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[5]}]
set_property PACKAGE_PIN N13      [get_ports {hyper_dq_io[6]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[6]}]
set_property PACKAGE_PIN M13      [get_ports {hyper_dq_io[7]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {hyper_dq_io[7]}]

set_property slew FAST [get_ports [list hyper_cs_no[*]]]
set_property slew FAST [get_ports [list hyper_ck_*]]

set_property PACKAGE_PIN H14      [get_ports {debug[0]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[0]}]
set_property PACKAGE_PIN J14      [get_ports {debug[1]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[1]}]
set_property PACKAGE_PIN G14      [get_ports {debug[2]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[2]}]
set_property PACKAGE_PIN G15      [get_ports {debug[3]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[3]}]
set_property PACKAGE_PIN J15      [get_ports {debug[4]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[4]}]
set_property PACKAGE_PIN J16      [get_ports {debug[5]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[5]}]
set_property PACKAGE_PIN G16      [get_ports {debug[6]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[6]}]
set_property PACKAGE_PIN H16      [get_ports {debug[7]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[7]}]
set_property PACKAGE_PIN G13      [get_ports {debug[8]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[8]}]
set_property PACKAGE_PIN H13      [get_ports {debug[9]}]
set_property IOSTANDARD HSTL_I_18 [get_ports {debug[9]}]

set_property slew FAST [get_ports debug[0]]
set_property slew FAST [get_ports debug[1]]
set_property slew FAST [get_ports debug[2]]
set_property slew FAST [get_ports debug[3]]
set_property slew FAST [get_ports debug[4]]
set_property slew FAST [get_ports debug[5]]
set_property slew FAST [get_ports debug[6]]
set_property slew FAST [get_ports debug[7]]
set_property slew FAST [get_ports debug[8]]
set_property slew FAST [get_ports debug[9]]
