VLOG_ARGS += -suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale \"1 ns / 1 ps\"
XVLOG_ARGS += -64bit -compile -vtimescale 1ns/1ns -quiet
BENDER ?= bender

define generate_vsim
	echo 'set ROOT [file normalize [file dirname [info script]]/$3]' > $1
	bender script vsim --vlog-arg="$(VLOG_ARGS)" $2 | grep -v "set ROOT" >> $1
	echo >> $1
	echo 'vlog "$$ROOT/test/elfloader.cpp" -ccflags "-std=c++11"' >> $1
endef

all: scripts/compile.tcl

scripts:
	mkdir -p scripts

scripts/compile.tcl: scripts
	$(call generate_vsim, $@, -t rtl -t test,..)

clean:
	rm -rf scripts
