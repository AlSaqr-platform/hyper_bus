
deleteAllPowerPreroutes
clearDrc

# Connect pad power pins.
sroute -connect { padRing  } -layerChangeRange { ME1(1) ME8(8) } -corePinTarget { firstAfterRowEnd } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -targetViaLayerRange { ME1(1) ME8(8) }

# Generate stride left and right of pads

set offset 1.5

for {set i 0} {$i < [llength $pins]} {incr i} {
	set lx [dbGet [dbGetInstByName [lindex $pins $i]].pt_x]
	puts $lx

	set start_x [expr $lx - 3]
	set stop_x [expr $lx + 60 + 1.5]

	set left_x [expr $lx - 3]
	set right_x [expr $lx + 60 + 0.5]

	#SKIP on first pad
	if {$i != 0} {
		#VSS left
	    addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 11.65 2358.2 100} -nets VSS -start_x $start_x -stacked_via_bottom_layer ME1

		#VDD left
		addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 9.85 2358.2 100} -nets VDD -start_x [expr $start_x + $offset] -stacked_via_bottom_layer ME1

		createPlaceBlockage -box [expr $lx - 3   ] 88.8 [expr $lx - 0.5] 100
	}

	#SKIP on last pad
    if {$i != [expr [llength $pins] - 1]} {
		#VSS right
	    addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 11.65 2358.2 100} -nets VSS -start_x $right_x -stacked_via_bottom_layer ME1

		#VDD right
		addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 9.85 2358.2 100} -nets VDD -start_x [expr $right_x + $offset] -stacked_via_bottom_layer ME1

		createPlaceBlockage -box [expr $lx + 60.5] 88.8 [expr $lx +  63] 100
    }
}

sroute -connect { corePin } -layerChangeRange { ME1(1) ME8(8) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { ME1(1) ME8(8) }

# add strips at top of power pads

set power_pads [list \
    pad_vss_c \
    pad_vdd_c \
]
set power_nets [list \
    VSS \
    VDD \
]
for {set i 0} {$i < [llength $power_pads]} {incr i} {
	set lx [dbGet [dbGetInstByName [lindex $power_pads $i]].pt_x]
	puts $lx

	set start_x [expr $lx + 6.2]
	set stop_x [expr $lx + 53.76]

	# connection for vdd pad do need an offset
	if {[lindex $power_nets $i] == {VDD}} {
		set start_x [expr $start_x + 0.02]
		set stop_x [expr $stop_x + 0.02]
	}

	for {set layer 1} {$layer < 9} {incr layer} {
		addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME$layer -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME$layer -number_of_sets 4 -skip_via_on_pin Standardcell -stacked_via_top_layer ME$layer -padcore_ring_top_layer_limit ME1 -merge_stripes_value 0.1 -layer ME$layer -block_ring_bottom_layer_limit ME$layer -width 10 -spacing 2 -area {0 88.8 2358.2 100} -nets [lindex $power_nets $i] -start_x $start_x -stop_x $stop_x -stacked_via_bottom_layer ME$layer
	}
}

puts "Finished power grid"