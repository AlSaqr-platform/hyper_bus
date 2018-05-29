# This script calculates the different delays the delay line can generate.
# Execute in Synopsys Design Compiler.

read_file -format verilog PROGDEL8.v
set delays {}
redirect PROGDEL8.delays.rpt { puts "S        delay" }

# delay 0 (S=00000001)
set_case_analysis 1 S[0]
set_case_analysis 0 S[1]
set_case_analysis 0 S[2]
set_case_analysis 0 S[3]
set_case_analysis 0 S[4]
set_case_analysis 0 S[5]
set_case_analysis 0 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "00000001 $delay" }

# delay 1 (S=00000010)
set_case_analysis 0 S[0]
set_case_analysis 1 S[1]
set_case_analysis 0 S[2]
set_case_analysis 0 S[3]
set_case_analysis 0 S[4]
set_case_analysis 0 S[5]
set_case_analysis 0 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "00000010 $delay" }

# delay 2 (S=00000100)
set_case_analysis 0 S[0]
set_case_analysis 0 S[1]
set_case_analysis 1 S[2]
set_case_analysis 0 S[3]
set_case_analysis 0 S[4]
set_case_analysis 0 S[5]
set_case_analysis 0 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "00000100 $delay" }

# delay 3 (S=00001000)
set_case_analysis 0 S[0]
set_case_analysis 0 S[1]
set_case_analysis 0 S[2]
set_case_analysis 1 S[3]
set_case_analysis 0 S[4]
set_case_analysis 0 S[5]
set_case_analysis 0 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "00001000 $delay" }

# delay 4 (S=00010000)
set_case_analysis 0 S[0]
set_case_analysis 0 S[1]
set_case_analysis 0 S[2]
set_case_analysis 0 S[3]
set_case_analysis 1 S[4]
set_case_analysis 0 S[5]
set_case_analysis 0 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "00010000 $delay" }

# delay 5 (S=00100000)
set_case_analysis 0 S[0]
set_case_analysis 0 S[1]
set_case_analysis 0 S[2]
set_case_analysis 0 S[3]
set_case_analysis 0 S[4]
set_case_analysis 1 S[5]
set_case_analysis 0 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "00100000 $delay" }

# delay 6 (S=01000000)
set_case_analysis 0 S[0]
set_case_analysis 0 S[1]
set_case_analysis 0 S[2]
set_case_analysis 0 S[3]
set_case_analysis 0 S[4]
set_case_analysis 0 S[5]
set_case_analysis 1 S[6]
set_case_analysis 0 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "01000000 $delay" }

# delay 7 (S=10000000)
set_case_analysis 0 S[0]
set_case_analysis 0 S[1]
set_case_analysis 0 S[2]
set_case_analysis 0 S[3]
set_case_analysis 0 S[4]
set_case_analysis 0 S[5]
set_case_analysis 0 S[6]
set_case_analysis 1 S[7]
redirect -variable T { report_timing -from A -to Z }
foreach line [split $T \n] { if [regexp "data arrival time\\s+(.*)" $line _ value] { set delay $value } }
redirect -append PROGDEL8.delays.rpt { puts "10000000 $delay" }
