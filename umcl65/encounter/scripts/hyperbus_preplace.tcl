

set lx [dbGet [dbGetInstByName i_deflate/pad_hyper_rwds_io].pt_x]
set ly 88.8
set ux [expr $lx + 60]
set uy 95

#createRegion i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/progdel8_i $lx $ly $ux $uy

set ddr_pins [list \
    i_deflate/pad_hyper_dq_io_0 \
    i_deflate/pad_hyper_dq_io_1 \
    i_deflate/pad_hyper_dq_io_2 \
    i_deflate/pad_hyper_dq_io_3 \
    i_deflate/pad_hyper_dq_io_4 \
    i_deflate/pad_hyper_dq_io_5 \
    i_deflate/pad_hyper_dq_io_6 \
    i_deflate/pad_hyper_dq_io_7 \
    i_deflate/pad_hyper_rwds_io \
]

set oddr_cells [list \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_0__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_1__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_2__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_3__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_4__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_5__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_6__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_out_bus_7__ddr_data \
    i_deflate/i_hyperbus/phy_i/ddr_data_strb \
]
for {set i 0} {$i < [llength $oddr_cells]} {incr i} {
    set lx [dbGet [dbGetInstByName [lindex $ddr_pins $i]].pt_x]
    puts $lx
    set ux [expr $lx + 60]
    createGuide [lindex $oddr_cells $i] $lx $ly $ux $uy
}

#createRegion

set iddr_cells [list \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_0__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_1__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_2__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_3__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_4__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_5__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_6__i_ddr_in \
    i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/ddr_out_bus_7__i_ddr_in \
]
for {set i 0} {$i < [llength $iddr_cells]} {incr i} {
    set lx [dbGet [dbGetInstByName [lindex $ddr_pins $i]].pt_x]
    puts $lx
    set ux [expr $lx + 60]
    createGuide [lindex $iddr_cells $i] $lx $ly $ux $uy
}

#Add layout of delay line
#readSdpFile -file ../src/delayline/PROGDEL8.sdp -hierPath i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/progdel8_i

#above rwds pad
#setObjFPlanBox RplGroup PROGDEL8 704.017 94.32 718.017 97.92
