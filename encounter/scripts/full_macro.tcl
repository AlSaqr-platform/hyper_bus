

setMultiCpuUsage -localCpu max

source src/hyperbus_macro.globals
init_design
setOptMode -timeDesignCompressReports false

source scripts/hyperbus_floorplan.tcl
source scripts/hyperbus_preplace.tcl


# Load power intent.
read_power_intent -cpf src/hyperbus_macro.cpf
commit_power_intent

globalNetConnect VSSIO -netlistOverride -pin VSSIO
globalNetConnect VDDIO -netlistOverride -pin VDDIO
globalNetConnect VDD -netlistOverride -pin VDD
globalNetConnect VSS -netlistOverride -pin VSS
timeDesign -prePlace -outDir reports/timing.preplace


# Add custom power grid on top of rows.
source scripts/hyperbus_power_grid.tcl

# Insert welltaps and tie cells.
source scripts/welltap.tcl

createPinGroup inChip -cell hyperbus_inflate -optimizeOrder
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin axi*
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin cfg*
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin clk*
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin hyper_cs_*
addPinToPinGroup -pinGroup inChip -cell hyperbus_inflate -pin hyper_reset
createPinGuide -name inChip -cell hyperbus_inflate -edge 1 -layer {M2 M4 M6}

reset_path_group -all
createBasicPathGroups -expanded
set inputs [get_ports hyper_*_io]
set outputs [get_ports {{hyper_dq_io[*]} hyper_rwds_io}]
set registers [all_registers]
group_path   -name hyperIn2reg -from $inputs -to $registers
group_path   -name reg2hyperOut -from $registers -to $outputs


# Placement flow
timeDesign -prePlace -outDir reports/timing.preplace
setPlaceMode -place_global_place_io_pins true
placeDesign
optDesign -drv -preCTS -outDir reports/timing.postplacedrv
#place_opt_design
source scripts/tiehilo.tcl
timeDesign -preCTS -outDir reports/timing.postplace

saveDesign save/preCTS

# TODO: Clock tree synthesis (rwds!)
source src/hyperbus_macro.ccopt.spec
ccopt_design -outDir reports/timing

mkdir -p reports/clock
report_ccopt_clock_trees -filename reports/clock/clock_trees.rpt
report_ccopt_skew_groups -filename reports/clock/skew_groups.rpt
timeDesign -postCTS -outDir reports/timing

saveDesign save/postCTS

# TODO: Routing
setNanoRouteMode -quiet -routeInsertAntennaDiode 1
routeDesign -globalDetail

timeDesign -postRoute -outDir reports/timing
timeDesign -postRoute -hold -outDir reports/timing

# TODO: Finishing (export all etc)

set DESIGNNAME hyperbus_macro
source scripts/checkdesign.tcl
source scripts/exportall.tcl


write_lef_abstract ./out/hyperbus_macro_0v2.lef -stripePin
saveDesign save/hyperbus_macro_0v2
write_model_timing ./out/hyperbus_macro_0v2.lib
