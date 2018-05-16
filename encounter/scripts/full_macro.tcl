

setMultiCpuUsage -localCpu max

source src/hyperbus_macro.globals
init_design
setOptMode -timeDesignCompressReports false



#Add layout of delay line
readSdpFile -file ../src/delayline/PROGDEL8.sdp -hierPath i_deflate/i_hyperbus/phy_i/i_read_clk_rwds/hyperbus_delay_line_i/progdel8_i

source scripts/hyperbus_floorplan.tcl
source scripts/hyperbus_preplace.tcl

# TODO: Add filler cell at L/R boundary?

# Load power intent.
read_power_intent -cpf src/hyperbus_macro.cpf
commit_power_intent

globalNetConnect VSSIO -netlistOverride -pin VSSIO
globalNetConnect VDDIO -netlistOverride -pin VDDIO
globalNetConnect VDD -netlistOverride -pin VDD
globalNetConnect VSS -netlistOverride -pin VSS

# Connect pad power pins.
sroute -connect { padRing  } -layerChangeRange { ME1(1) ME8(8) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { ME1(1) ME8(8) }

# Add custom power grid on top of rows.
source scripts/hyperbus_power_grid.tcl
sroute -connect { corePin } -layerChangeRange { ME1(1) ME8(8) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin } -allowJogging 1 -crossoverViaLayerRange { ME1(1) ME8(8) } -nets { VDDIO VSSIO VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { ME1(1) ME8(8) }

#deleteAllPowerPreroutes

# Insert welltaps and tie cells.
source scripts/welltap.tcl

createPinGroup inChip -cell hyperbus_inflate -optimizeOrder
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin axi*
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin cfg*
createPinGuide -name inChip -cell hyperbus_inflate -edge 1 -layer {M2 M4 M6}

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
