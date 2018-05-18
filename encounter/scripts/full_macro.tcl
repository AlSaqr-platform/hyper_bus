

setMultiCpuUsage -localCpu max

source src/hyperbus_macro.globals
init_design
setOptMode -timeDesignCompressReports false


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

# Add custom power grid on top of rows.
source scripts/hyperbus_power_grid.tcl

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
source src/hyperbus_macro.ccopt.spec
ccopt_design -outDir reports/timing

mkdir -p reports/clock
report_ccopt_clock_trees -filename reports/clock/clock_trees.rpt
report_ccopt_skew_groups -filename reports/clock/skew_groups.rpt

# TODO: Routing
setNanoRouteMode -quiet -routeInsertAntennaDiode 1
routeDesign -globalDetail

timeDesign -postRoute -outDir reports/timing
timeDesign -postRoute -hold -outDir reports/timing

# TODO: Finishing (export all etc)

set DESIGNNAME hyperbus_macro
source scripts/checkdesign.tcl
source scripts/exportall.tcl
