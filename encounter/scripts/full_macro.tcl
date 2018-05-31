

setMultiCpuUsage -localCpu max

source src/hyperbus_macro.globals
init_design
setOptMode -timeDesignCompressReports false

source scripts/hyperbus_floorplan.tcl
source scripts/hyperbus_preplace.tcl


globalNetConnect VSSIO -netlistOverride -pin VSSIO
globalNetConnect VDDIO -netlistOverride -pin VDDIO
globalNetConnect VDD   -netlistOverride -pin VDD
globalNetConnect VSS   -netlistOverride -pin VSS


# Load power intent.
read_power_intent -cpf src/hyperbus_macro.cpf
commit_power_intent

globalNetConnect VSSIO -netlistOverride -pin VSSIO
globalNetConnect VDDIO -netlistOverride -pin VDDIO
globalNetConnect VDD   -netlistOverride -pin VDD
globalNetConnect VSS   -netlistOverride -pin VSS



reset_path_group -all
createBasicPathGroups -expanded
set inputs [get_ports hyper_*_io]
set outputs [get_ports {{hyper_dq_io[*]} hyper_rwds_io}]
set registers [all_registers]
group_path   -name hyperIn2reg -from $inputs -to $registers
group_path   -name reg2hyperOut -from $registers -to $outputs
timeDesign -prePlace -outDir reports/timing.preplace


# Add custom power grid on top of rows.
source scripts/hyperbus_power_grid.tcl


# Insert welltaps and tie cells.
source scripts/welltap.tcl

#place in chip pins
source scripts/place_pins.tcl


timeDesign -prePlace -outDir reports/timing.preplace
saveDesign save/prePlace


# Placement flow
setPlaceMode -place_global_place_io_pins true
place_opt_design
source scripts/tiehilo.tcl
timeDesign -preCTS -outDir reports/timing.postplace

saveDesign save/preCTS

# Clock tree synthesis
source src/hyperbus_macro.ccopt.spec
ccopt_design -outDir reports/timing

mkdir -p reports/clock
report_ccopt_clock_trees -filename reports/clock/clock_trees.rpt
report_ccopt_skew_groups -filename reports/clock/skew_groups.rpt
timeDesign -postCTS -outDir reports/timing.postCTS
timeDesign -hold -postCTS -outDir reports/timing.postCTS

saveDesign save/postCTS

# fix new violations
#place_opt_design

# Routing
setNanoRouteMode -quiet -routeInsertAntennaDiode 1
routeDesign -globalDetail

timeDesign -postRoute -outDir reports/timing.postroute
timeDesign -postRoute -hold -outDir reports/timing.postroute

saveDesign save/postRoute

source scripts/fillcore-insert.tcl

# doesn't work, density 100%
ecoPlace

# Finishing (export all etc)
source scripts/checkdesign.tcl
saveDesign save/hyperbus_macro_${VERSION}
# write_io_file

set VERSION wip
set DESIGNNAME hyperbus_macro_$VERSION

source scripts/exportall.tcl

write_lef_abstract ./out/hyperbus_macro_${VERSION}.lef -stripePin -PGpinLayers { 2 3 4 5 6 7 8 }

set_analysis_view -setup { func_view hold_view } \
                  -hold  { func_view hold_view }
foreach view {func_view hold_view} {
    puts "generating LIB view $view"
    do_extract_model -view $view out/hyperbus_macro_${VERSION}_${view}.lib
}
