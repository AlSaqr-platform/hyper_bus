set FPBOX {0.0 0.0 2358.2 100.0}
floorPlan -b [concat $FPBOX $FPBOX $FPBOX]
# setInstancePlacementStatus -status unplaced -name pad_*

set pins [list \
	pad_hyper_ck_no \
	pad_hyper_ck_o \
	pad_hyper_rwds_io \
	pad_hyper_dq_io_0 \
	pad_hyper_dq_io_1 \
	pad_hyper_dq_io_2 \
	pad_hyper_dq_io_3 \
	pad_hyper_dq_io_4 \
	pad_hyper_dq_io_5 \
	pad_hyper_dq_io_6 \
	pad_hyper_dq_io_7
]
set stride [expr (2358.2 - 200 - 60) / 10]
for {set i 0} {$i < [llength $pins]} {incr i} {
	set x [expr $i * $stride + 100]
	placeInstance [lindex $pins $i] $x 0.0 R0
}
