set pargs [list]

if { [info exists RX_DELAY] } { lappend pargs "+RX_DELAY=${RX_DELAY}"}

eval vsim hyperbus_udma_tb -t 1ps -voptargs=+acc -classdebug -sdfnoerror $pargs

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

delete wave *
