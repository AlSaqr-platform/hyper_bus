GIT ?= git
BENDER ?= bender
VSIM ?= vsim

all: sim_all

clean: sim_clean

# Ensure half-built targets are purged
.DELETE_ON_ERROR:

# --------------
# RTL SIMULATION
# --------------

VLOG_ARGS += -suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale \"1 ns / 1 ps\"
XVLOG_ARGS += -64bit -compile -vtimescale 1ns/1ns -quiet

define generate_vsim
	echo 'set ROOT [file normalize [file dirname [info script]]/$3]' > $1
	bender script $(VSIM) --vlog-arg="$(VLOG_ARGS)" $2 | grep -v "set ROOT" >> $1
	echo >> $1
	#echo 'vlog "$$ROOT/test/elfloader.cpp" -ccflags "-std=c++11"' >> $1 # TODO: Reactivate elf loader later?
endef

sim_all: scripts/compile.tcl
sim_all: models/generic_delay_D4_O1_3P750_CG0.behav.sv

sim_clean:
	rm -rf scripts/compile.tcl
	rm -rf work

scripts/compile.tcl: Bender.yml
	$(call generate_vsim, $@, -t rtl -t test,..)

# --------------
# GENERIC-DELAY
# --------------

BUILD_DIR ?= /dev/shm/hyper

DELAY_REMOTE ?= git@iis-git.ee.ethz.ch:bslk/generic-delay.git
DELAY_TAG ?= master

DELAY_REPO ?= $(BUILD_DIR)/generic-delay
DELAY_OUTDIR ?= $(BUILD_DIR)/generic-delay-build
DELAY_TECH ?= tsmc65
export

-include $(DELAY_REPO)/delay.mk

DELAY_FILEPATHS ?= \
	models/generic_delay_D4_O1_3P750_CG0.behav.sv

.PHONY: delay_clean

delay_clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DELAY_OUTDIR)
	rm -rf $(DELAY_FILEPATHS)

$(DELAY_REPO)/delay.mk:
	mkdir -p $(BUILD_DIR)
	rm -rf $(DELAY_REPO)
	$(GIT) clone $(DELAY_REMOTE) $(DELAY_REPO) && cd $(DELAY_REPO) && $(GIT) checkout $(DELAY_TAG)

.SECONDEXPANSION:
$(DELAY_FILEPATHS): $$(DELAY_OUTDIR)/$$(notdir $$@)
	mkdir -p $(dir $@)
	cp $< $@
