set FPBOX {0.0 0.0 2358.2 100.0}
set COREBOX {0.0 10 2358.2 100.0}
floorPlan -b [concat $FPBOX $FPBOX $COREBOX]
# setInstancePlacementStatus -status unplaced -name pad_*

set pins [list \
    pad_vdd_p \
    pad_hyper_ck_no \
    pad_hyper_ck_o \
    pad_hyper_rwds_io \
    pad_hyper_dq_io_0 \
    pad_hyper_dq_io_1 \
    pad_vss_c \
    pad_vdd_c \
    pad_hyper_dq_io_2 \
    pad_hyper_dq_io_3 \
    pad_hyper_dq_io_4 \
    pad_hyper_dq_io_5 \
    pad_hyper_dq_io_6 \
    pad_hyper_dq_io_7 \
    pad_vss_p \
]
set stride [expr (2358.2 - 200 - 60) / ([llength $pins]-1)]
for {set i 0} {$i < [llength $pins]} {incr i} {
    set x [expr $i * $stride + 100 ]
    placeInstance [ lindex $pins $i ] $x 0.0 R0
}

placeInstance filler5_left 0.0 0.0 R0
placeInstance filler5_right [expr 2358.2 - 5] 0.0 R0

