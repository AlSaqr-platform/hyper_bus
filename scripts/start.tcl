vsim hyperbus_udma_tb -t 1ps -voptargs=+acc -classdebug -sdfnoerror

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

delete wave *
