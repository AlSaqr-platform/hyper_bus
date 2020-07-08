
deleteAllPowerPreroutes
clearDrc

# Connect pad power pins.
# sroute -connect { padRing  } -layerChangeRange { ME1(1) ME8(8) } -corePinTarget { firstAfterRowEnd } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -targetViaLayerRange { ME1(1) ME8(8) }

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
    if {$i > 3 && $i < [expr [llength $pins] - 2]} {
        #VSS left
        addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 11.65 2358.2 100} -nets VSS -start_x $start_x -stacked_via_bottom_layer ME1

        #VDD left
        addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 9.85 2358.2 100} -nets VDD -start_x [expr $start_x + $offset] -stacked_via_bottom_layer ME1

        createPlaceBlockage -box [expr $lx - 3.2   ] 88.8 [expr $lx - 0.3] 100
    }

    #SKIP on last pad
    if {$i > 3 && $i < [expr [llength $pins] - 2]} {
        #VSS right
        addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 11.65 2358.2 100} -nets VSS -start_x $right_x -stacked_via_bottom_layer ME1

        #VDD right
        addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME1 -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME1 -number_of_sets 1 -skip_via_on_pin Standardcell -stacked_via_top_layer ME8 -padcore_ring_top_layer_limit ME1 -spacing 2 -merge_stripes_value 0.1 -layer ME2 -block_ring_bottom_layer_limit ME1 -width 1 -area {0 9.85 2358.2 100} -nets VDD -start_x [expr $right_x + $offset] -stacked_via_bottom_layer ME1

        createPlaceBlockage -box [expr $lx + 60.3 ] 88.8 [expr $lx +  63.2] 100
    }
}


# add halo around pads to prevent dangling follow stripes
addHaloToBlock {3.5 0 3.5 0.5} -allIOPad 

sroute -connect { corePin } -layerChangeRange { ME1(1) ME8(8) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { ME1(1) ME8(8) } 


# add strips at top of power pads


editTrim -nets {VDD VSS}


# has to be after editTrim
set stripes_name [list \
    VSS     \
    VSSIO   \
    VSSIO   \
    VDDIO   \
    VSS     \
    VDDIO   \
    VDDIO   \
    VSS     \
    VDD     \
]

set strips_y0 [list \
     0.100  \
     7.010  \
    20.010  \
    33.020  \
    34.420  \
    37.740  \
    50.740  \
    63.340  \
    76.370  \
]

set strips_y1 [list \
     1.100  \
    16.810  \
    29.810  \
    34.020  \
    35.420  \
    47.140  \
    60.140  \
    73.990  \
    84.800  \
]

set stripe_layers [list \
    {7 6 5 4 3 1} \
    {7 6 5 4} \
    {7 6 5 4} \
    {7 6 5 4} \
    {7 6 5 4} \
    {7 6 5 4} \
    {7 6 5 4} \
    {7 6 5 4} \
    {8 7 6 5 4} \
]

set x_start [expr ( [dbGet [dbGetInstByName pad_vdd_c2].pt_x] + 60 -1 )*1000 ]
set x_stop  [expr ( [dbGet [dbGetInstByName i_deflate/pad_hyper_dq_io_3].pt_x] + 1 ) * 1000 ]

redirect src/hyper_macro.power_generated.def {
    puts "VERSION 5.8 ;"
    puts "DIVIDERCHAR \"/\" ;"
    puts "BUSBITCHARS \"[]\" ;"
    puts "DESIGN hyperbus_macro_inflate ;"
    puts "UNITS DISTANCE MICRONS 1000 ;"
    puts ""
    set n [llength $stripes_name]
    puts "SPECIALNETS $n ;"
    
    foreach name $stripes_name y0 $strips_y0 y1 $strips_y1 layers $stripe_layers {
        set width [expr ($y1 - $y0) * 1000]
        set y [expr $y0*1000 + $width/2]

        puts "- $name  ( * $name )"
        set i 0
        foreach layer $layers {
            if {$i == 0} {
                puts -nonewline "  + ROUTED"
                set i 1
            } else {
                puts -nonewline "    NEW"
            }
            puts " ME$layer $width + SHAPE STRIPE ( $x_start $y ) ( $x_stop * )"
        }
        if {[string match VSS* $name]} {
            puts "  + USE GROUND"
        } else {
            puts "  + USE POWER"
        }
        puts " ;"
    }
    puts "END SPECIALNETS"
    puts "END DESIGN"
}



defIn -specialnets src/hyper_macro.power_generated.def 

editPowerVia -skip_via_on_pin Standardcell -bottom_layer ME2 -same_sized_stack_vias 1 -via_using_exact_crossover_size 0 -add_vias 1 -split_vias 1 -orthogonal_only 0 -top_layer ME8

# has to be after editPowerVia
set power_pads [list \
    pad_vss_c1 \
    pad_vss_c2 \
    pad_vdd_c1 \
    pad_vdd_c2 \
]
set power_nets [list \
    VSS \
    VSS \
    VDD \
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

    foreach layer {2 4 6 8} {
        addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit ME$layer -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit ME$layer -number_of_sets 4 -skip_via_on_pin Standardcell -stacked_via_top_layer ME$layer -padcore_ring_top_layer_limit ME1 -merge_stripes_value 0.1 -layer ME$layer -block_ring_bottom_layer_limit ME$layer -width 10 -spacing 2 -area {450 88.8 2258.2 235} -nets [lindex $power_nets $i] -start $start_x -stop $stop_x -stacked_via_bottom_layer ME$layer -create_pins 1
    }

    createPlaceBlockage -box [expr $start_x - 0.3 ] 88.8 [expr $stop_x + 0.3 ] 100
}

#-extend_to design_boundary

puts "Finished power grid"

