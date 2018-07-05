#
# export all relevant design data
#
# v0.5 - <muheim@ee.ethz.ch> - Mon Oct  2 16:08:39 CEST 2017
#  - add -virtualConnection false to setStreamOutMode
#    to avoid appending a (:) to the pin label of power ground
# v0.4  - <muheim@ee.ethz.ch> - Tue Aug  9 10:46:07 CEST 2016
#  - writing comment for the write sdf 
#  - set the ExtractRCMode only if it is not ready set,
#    this can lat it not re extract the rc new
# v0.3  - <muheim@ee.ethz.ch> - Wed Jul  2 17:06:15 CEST 2014
#  - remufe the  -remashold and add -nonegchecks to the write_sdf
#  - write the verilog for simulation without physical cells
#  - change the write_sdf, so also the view will taken out of the
#    nalysis_views lists.
# v0.2  - <muheim@ee.ethz.ch> - Thu Aug  4 16:02:55 CEST 2011
#  - add this global variable for proper sdf out
# v0.1  - <muheim@ee.ethz.ch> - Thu Jun 16 11:24:22 CEST 2011
#  - copy from umcL90
#  - use write_sdf as standart and add the views


# is the design name specified ???
if { [ info exists DESIGNNAME ] } {
   set NAME "$DESIGNNAME"

} else {
    set NAME "final"

}

puts ""
puts "Writing SDF \"out/${NAME}.sdf.gz\" ..."
puts ""
puts "        ****** Write out the SDF tripl ******"
puts "               min cornner (first hold analysis views)  : [lindex [all_setup_analysis_views] 2]" 
puts "               typ cornner (first setup analysis views) : [lindex [all_setup_analysis_views] 1]" 
puts "               max cornner (first setup analysis views) : [lindex [all_setup_analysis_views] 0]" 

# RC will be extracted, if not ready set, will set the used engine to the
# Integrated QRC (IQRC) engine.
if { [getExtractRCMode -quiet -engine] ne "postRoute"} {
  puts "set: setExtractRCMode -engine postRoute"
  setExtractRCMode -engine postRoute
  if { [getExtractRCMode -quiet -effortLevel] ne "high" && [getExtractRCMode -quiet -effortLevel] ne "signoff"} {
    puts "set: setExtractRCMode -effortLevel high"
    setExtractRCMode -effortLevel high
  }
}

# global variable for written the sdf checks checks correctly with a tripl
set_global timing_recompute_sdf_in_setuphold_mode true

# Write out SDF, take the first analysis_views from the hold and the setup list
write_sdf -precision 4 -min_period_edges posedge -recompute_parallel_arcs -nonegchecks \
          -min_view func_bc \
          -typ_view func_tc \
          -max_view func_wc \
          out/${NAME}.sdf.gz
puts ""

# This netlist do not contains the filler cells, physical cells.
# This can be used for simulation 
saveNetlist out/${NAME}.v -excludeLeafCell

# This netlist contains all filler cells and everything.
# This have to be used for LVS 
saveNetlist out/${NAME}_lvs.v -excludeLeafCell -includePhysicalInst -phys

# layout
setStreamOutMode -SEvianames ON -specifyViaName %t_VIA -virtualConnection false

# you can set an alternative top name with -structureName 
# streamOut out/${NAME}.gds.gz -structureName sem01w0 
streamOut out/${NAME}.gds.gz  -mapFile tech/streamOut_noObs.map -outputMacros -merge {  \
  /usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbl/b03/gds/uk65lscllmvbbl.gds \
  /usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbr/b03/gds/uk65lscllmvbbr.gds \
  /usr/pack/umc-65-kgf/umc/ll/uk65lscllmvbbh/b03/gds/uk65lscllmvbbh.gds \
  /usr/pack/umc-65-kgf/umc/ll/u065gioll25mvir/b04/gds/u065gioll25mvir_8m1t0f1u.gds \
 }

