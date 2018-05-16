

set start_x 160.32
set stop_x [expr 2358.2 - 100 + 0.32 + 2]

# #VSS right of Pad
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 15 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -stop_x $stop_x -width 2 -area {0 11.65 2358.2 100} -nets VSS -start_x $start_x -stacked_via_bottom_layer ME1

# #VDD right of Pad
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 15 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -stop_x [expr $stop_x + 3] -width 2 -area {0 9.85 2358.2 100} -nets VDD -start_x [expr $start_x + 3] -stacked_via_bottom_layer ME1

set offset [expr -65.62]

#VSS right of Pad
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 15 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -stop_x [expr $stop_x + $offset] -width 2 -area {0 11.65 2358.2 100} -nets VSS -start_x [expr $start_x + $offset] -stacked_via_bottom_layer ME1

#VDD right of Pad
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 15 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -stop_x [expr $stop_x + $offset + 3] -width 2 -area {0 9.85 2358.2 100} -nets VDD -start_x [expr $start_x + $offset + 3] -stacked_via_bottom_layer ME1


# VSS and VDD for filler left
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -xleft_offset 5.32 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 2 -area {0 11.65 2358.2 100} -nets VSS -stacked_via_bottom_layer ME1

addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -xleft_offset [expr 5.32+3] -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 2 -area {0 9.85 2358.2 100} -nets VDD -stacked_via_bottom_layer ME1

# VSS and VDD for filler right
addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -xright_offset [expr 5.32+3] -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 2 -area {0 11.65 2358.2 100} -nets VSS -stacked_via_bottom_layer ME1 -start_from right

addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -xright_offset [expr 5.32] -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 2 -area {0 9.85 2358.2 100} -nets VDD -stacked_via_bottom_layer ME1 -start_from right