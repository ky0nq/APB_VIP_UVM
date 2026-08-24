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
#   make cov
#   make cov_wave
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
# Coverage
# ------------------------------------------------------------
COV_DIR     := coverage.vdb
COV_REPORT  := coverage_report

COV_METRICS := line+cond+fsm+tgl+branch+assert

# ------------------------------------------------------------
# Source files
# ------------------------------------------------------------
RTL_SRCS := $(sort \
	$(wildcard $(RTL_DIR)/*.v) \
	$(wildcard $(RTL_DIR)/*.sv))

# apb_pkg.sv includes UVM class files.
# Compile interface -> assertion -> package -> top.
TB_SRCS := \
	$(TB_DIR)/apb_if.sv \
	$(TB_DIR)/apb_assertions.sv \
	$(TB_DIR)/apb_pkg.sv \
	$(TB_DIR)/tb_top.sv

# Recompile when any TB file changes.
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
	-kdb \
	-cm $(COV_METRICS) \
	-cm_dir $(COV_DIR)

.PHONY: all sim run wave cov cov_wave clean help

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
# Run UVM Simulation + Coverage
# ============================================================
run: sim
	./$(SIMV) \
		+UVM_TESTNAME=$(TEST) \
		+UVM_VERBOSITY=$(VERBOSITY) \
		-cm $(COV_METRICS) \
		-cm_dir $(COV_DIR) \
		-cm_name $(TEST) \
		-l $(RUN_LOG)

# ============================================================
# Open Waveform
# ============================================================
wave: run
	verdi -ssf $(WAVE_FILE) &

# ============================================================
# Generate Coverage Report
# ============================================================
cov: run
	urg \
		-dir $(COV_DIR) \
		-report $(COV_REPORT)

	@echo ""
	@echo "========================================"
	@echo " Coverage Report Generated"
	@echo "========================================"
	@echo "Database : $(COV_DIR)"
	@echo "Report   : $(COV_REPORT)"
	@echo "========================================"

# ============================================================
# Open Coverage with Verdi
# ============================================================
cov_wave: cov
	verdi -cov -covdir $(COV_DIR) &

# ============================================================
# Clean
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
		$(COV_DIR) \
		$(COV_REPORT) \
		*.vdb \
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
	@echo "  Run UVM simulation and collect coverage"
	@echo ""
	@echo "make run TEST=apb_basic_test VERBOSITY=UVM_HIGH"
	@echo "  Run selected test with higher verbosity"
	@echo ""
	@echo "make wave"
	@echo "  Run simulation and open FSDB waveform in Verdi"
	@echo ""
	@echo "make cov"
	@echo "  Run simulation and generate coverage report"
	@echo ""
	@echo "make cov_wave"
	@echo "  Generate coverage report and open coverage in Verdi"
	@echo ""
	@echo "make clean"
	@echo "  Remove generated files"
