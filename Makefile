# ============================================================
# APB UVM - Synopsys VCS Makefile
#
# Project structure
# .
# ├── rtl/
# ├── tb/
# └── Makefile
#
# Usage
#   make sim
#   make run
#   make wave
#   make clean
# ============================================================

TEST        ?= apb_basic_test
VERBOSITY   ?= UVM_MEDIUM
TOP         ?= tb_top

RTL_DIR     := rtl
TB_DIR      := tb

SIMV        := simv
COMPILE_LOG := compile.log
RUN_LOG     := sim.log
WAVE_FILE   := wave.fsdb

# ------------------------------------------------------------
# Source files
# ------------------------------------------------------------
RTL_SRCS := $(sort \
	$(wildcard $(RTL_DIR)/*.v) \
	$(wildcard $(RTL_DIR)/*.sv))

# apb_pkg.sv includes the UVM class files.
# Therefore compile only interface -> package -> top directly.
TB_SRCS := \
	$(TB_DIR)/apb_if.sv \
	$(TB_DIR)/apb_pkg.sv \
	$(TB_DIR)/tb_top.sv

# Recompile if any included TB class changes.
TB_DEPS := $(wildcard $(TB_DIR)/*.sv)

INC_DIRS := \
	+incdir+$(TB_DIR) \
	+incdir+$(RTL_DIR)

# ------------------------------------------------------------
# VCS options
# ------------------------------------------------------------
VCS_FLAGS := \
	-full64 \
	-sverilog \
	-ntb_opts uvm \
	-timescale=1ns/1ps \
	-debug_access+all \
	-kdb

.PHONY: all sim run wave clean help

all: run

# ============================================================
# Compile + Elaborate
# ============================================================
sim: $(SIMV)

$(SIMV): $(RTL_SRCS) $(TB_DEPS)
	vcs $(VCS_FLAGS) \
		$(INC_DIRS) \
		$(RTL_SRCS) \
		$(TB_SRCS) \
		-top $(TOP) \
		-o $(SIMV) \
		-l $(COMPILE_LOG)

# ============================================================
# Run UVM simulation
# ============================================================
run: sim
	./$(SIMV) \
		+UVM_TESTNAME=$(TEST) \
		+UVM_VERBOSITY=$(VERBOSITY) \
		-l $(RUN_LOG)

# ============================================================
# Run simulation + open waveform with DVE
# Requires tb_top.sv to generate wave.vpd
# ============================================================
wave: run
	verdi -ssf $(WAVE_FILE) &

# ============================================================
# Clean generated files
# ============================================================
clean:
	rm -rf \
		$(SIMV) \
		simv.daidir \
		csrc \
		ucli.key \
		vc_hdrs.h \
		DVEfiles \
		novas.conf \
		novas.rc \
		verdiLog \
		AN.DB \
		*.vpd \
		*.vcd \
		*.fsdb \
		*.log

# ============================================================
# Help
# ============================================================
help:
	@echo "make sim"
	@echo "  Compile and elaborate with VCS"
	@echo ""
	@echo "make run"
	@echo "  Run UVM simulation"
	@echo ""
	@echo "make run TEST=apb_test VERBOSITY=UVM_HIGH"
	@echo "  Run selected test with higher verbosity"
	@echo ""
	@echo "make wave"
	@echo "  Run simulation and open wave.vpd in DVE"
	@echo ""
	@echo "make clean"
	@echo "  Remove generated files"
