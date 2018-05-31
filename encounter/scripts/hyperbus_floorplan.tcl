set FPBOX {0.0 0.0 2358.2 100.0}
set coreOffsetSie 163.5
floorPlan -b [concat $FPBOX $FPBOX $coreOffsetSie 10 [expr 2358.2 - $coreOffsetSie] 99]

# setInstancePlacementStatus -status unplaced -name pad_*

addInst  -cell IVSS -inst pad_vss_c
addInst  -cell IVSSIO -inst pad_vss_p
addInst  -cell IVDD -inst pad_vdd_c
addInst  -cell IVDDIO -inst pad_vdd_p

set pins [list \
    pad_vss_c \
    i_deflate/pad_hyper_ck_o \
    i_deflate/pad_hyper_ck_no \
    i_deflate/pad_hyper_rwds_io \
    i_deflate/pad_hyper_dq_io_0 \
    i_deflate/pad_hyper_dq_io_1 \
    pad_vdd_p \
    pad_vss_p \
    i_deflate/pad_hyper_dq_io_2 \
    i_deflate/pad_hyper_dq_io_3 \
    i_deflate/pad_hyper_dq_io_4 \
    i_deflate/pad_hyper_dq_io_5 \
    i_deflate/pad_hyper_dq_io_6 \
    i_deflate/pad_hyper_dq_io_7 \
    pad_vdd_c \
]
set placement [linsert $pins 8 skip]
set stride [expr (2358.2 - 200 - 60) / ([llength $placement]-1)]
for {set i 0} {$i < [llength $placement]} {incr i} {
    if {$i == 8} {
        puts $i
        continue
    }
    set x [expr $i * $stride + 100 ]
    placeInstance [ lindex $placement $i ] $x 0.0 R0
}

#

addIoFiller -cell IFILLER5 -side bottom -from 0 -to 100
addIoFiller -cell IFILLER5 -side bottom -from 2258.2 -to 2358.2
addIoFiller -cell IFILLER5 -side bottom -from 140 -to 1107
addIoFiller -cell IFILLER1 -side bottom -from 140 -to 1107
addIoFiller -cell IFILLER5 -side bottom -from 1670 -to 2230
addIoFiller -cell IFILLER1 -side bottom -from 1670 -to 2230



# deleteInst filler_*

# addInst  -cell IFILLER10 -inst filler_left1
# addInst  -cell IFILLER10 -inst filler_right1
# addInst  -cell IFILLER10 -inst filler_left2
# addInst  -cell IFILLER10 -inst filler_right2

# placeInstance filler_left1 0.0 0.0 R0
# placeInstance filler_right1 [expr 2358.2 - 10] 0.0 R0
# placeInstance filler_left2 10 0.0 R0
# placeInstance filler_right2 [expr 2358.2 - 20] 0.0 R0
