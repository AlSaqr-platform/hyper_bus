

source src/hyperbus_macro.globals
init_design
setOptMode -timeDesignCompressReports false
readSdpFile -file ../src/delayline/PROGDEL8.sdp -hierPath i_hyperbus/i_deflate/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/progdel8_i

source scripts/hyperbus_floorplan.tcl

# TODO: Add filler cell at L/R boundary?

# Load power intent.
read_power_intent -cpf src/hyperbus_macro.cpf
commit_power_intent

# Connect pad power pins.
sroute -connect { blockPin padPin padRing corePin floatingStripe } -layerChangeRange { ME1(1) ME8(8) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { ME1(1) ME8(8) }

# Add custom power grid on top of rows.

# Insert welltaps and tie cells.
source scripts/welltap.tcl

# Placement flow
timeDesign -prePlace -outDir reports/timing.preplace
setPlaceMode -place_global_place_io_pins true
place_opt_design
source scripts/tiehilo.tcl
timeDesign -preCTS -outDir reports/timing.postplace

# TODO: Clock tree synthesis (rwds!)
# TODO: Routing
# TODO: Finishing (export all etc)

source scripts/checkdesign.tcl
source scripts/exportall.tcl
