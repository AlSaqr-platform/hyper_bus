#!/usr/bin/env python3
# Copyright (c) 2018 Fabian Schuiki
#
# This script generates the netlist and SDP description of a delay line.

import sys
import argparse

# Parse the command line arguments.
parser = argparse.ArgumentParser()
parser.add_argument("N", help="number of delay stages")
args = parser.parse_args()

# Prepare names and parameters.
N = int(args.N)
MODNAME = "PROGDEL%d" % N

# Generate the netlist.
with open("%s.v" % MODNAME, "w") as netlist:
	netlist.write("module %s (A,S,Z);\n" % MODNAME)
	netlist.write("    input A;\n")
	netlist.write("    input [%d:0] S;\n" % (N-1))
	netlist.write("    output Z;\n")
	netlist.write("\n")
	netlist.write("    wire [%d:0] delayed;\n" % (N-1))
	netlist.write("    wire [%d:0] muxed;\n" % (N-1))
	netlist.write("\n")
	for i in range(N-1):
		netlist.write("    DEL4M1R delay%d (.A(delayed[%d]), .Z(delayed[%d]));\n" % (i, i, i+1))
	netlist.write("\n")
	for i in range(N-1):
		netlist.write("    CKMUX2M2R mux%d (.A(muxed[%d]), .B(delayed[%d]), .S(S[%d]), .Z(muxed[%d]));\n" % (i, i+1, i, i, i))
	netlist.write("\n")
	netlist.write("    assign delayed[0] = A;\n")
	netlist.write("    assign muxed[%d] = delayed[%d];\n" % (N-1, N-1))
	netlist.write("    assign Z = muxed[0];\n")
	netlist.write("endmodule\n")

# Generate the delay calculation script.
with open("%s.delays.tcl" % MODNAME, "w") as tcl:
	tcl.write("# This script calculates the different delays the delay line can generate.\n")
	tcl.write("# Execute in Synopsys Design Compiler.\n")
	tcl.write("\n")
	tcl.write("read_file -format verilog %s.v\n" % MODNAME)
	tcl.write("set delays {}\n")
	tcl.write("redirect %s.delays.rpt { puts \"%s delay\" }\n" % (MODNAME, "S".ljust(N)))
	for i in range(N):
		ib = '{0:0{1}b}'.format(1 << i, N)
		tcl.write("\n")
		tcl.write("# delay %d (S=%s)\n" % (i, ib))
		for n in range(N):
			tcl.write("set_case_analysis %d S[%d]\n" % (n == i, n))
		tcl.write("redirect -variable T { report_timing -from A -to Z }\n")
		tcl.write("foreach line [split $T \\n] { if [regexp \"data arrival time\\\\s+(.*)\" $line _ value] { set delay $value } }\n")
		tcl.write("redirect -append %s.delays.rpt { puts \"%s $delay\" }\n" % (MODNAME, ib))

# Generate the SDP file.
with open("%s.sdp" % MODNAME, "w") as sdp:
	sdp.write("datapath %s {\n" % MODNAME)
	sdp.write("  row %s {\n" % MODNAME)
	for i in range(N-1):
		sdp.write("    column stage%d {\n" % i)
		sdp.write("      inst mux%d\n" % i)
		sdp.write("      inst delay%d\n" % i)
		sdp.write("    }\n")
	sdp.write("  }\n")
	sdp.write("}\n")
