TOP := top
SOURCE_FILES_SV := $(REPO_ROOT)/sources_sv.f
SOURCE_FILES_VHD := $(REPO_ROOT)/sources_vhd.f
VERILOG_DEFINES := -d HIER_ACCESS
COMP_OPTS_SV := -sv --incr --relax  -L uvm -L uvm
COMP_OPTS_VHD := --incr --relax
DPI_ROOT := $(REPO_ROOT)/aes-256_model
DPI_SRCS := $(DPI_ROOT)/aes.c $(DPI_ROOT)/aes_dpi.c
DPI_OUT := aes_dpi.so
DPI_LOG := aes_dpi.log
ELAB_DEBUG := typical
ELAB_OPTS := -debug $(ELAB_DEBUG) --incr --relax -L uvm -sv_lib $(DPI_OUT) -cc_type t --mt 8

TCLBATCH := $(REPO_ROOT)/run_cfg.tcl
UVM_VERBOSITY := UVM_LOW
UVM_TESTNAME := aes256_test_smoke
SEED := 10
FUNC_COV := FUNC_COVERAGE

all: sim

$(DPI_OUT): $(DPI_SRCS)
	@echo "Building DPI model"
	xsc $(DPI_SRCS) -o $(DPI_OUT) > $(DPI_LOG) 2>&1
	@echo "DPI model built"

compile: .compile.touchfile
.compile.touchfile:
	@echo "Compiling SystemVerilog"
	xvlog $(COMP_OPTS_SV) -prj $(SOURCE_FILES_SV) $(VERILOG_DEFINES) > /dev/null 2>&1
	@echo "Compiling VHDL"
	xvhdl $(COMP_OPTS_VHD) -prj $(SOURCE_FILES_VHD) > /dev/null 2>&1
	touch .compile.touchfile
	@echo "RTL compilation done"

elab: .elab.touchfile
.elab.touchfile: .compile.touchfile $(DPI_OUT)
	@echo "Elaborating design"
	xelab $(TOP) $(ELAB_OPTS) $(VERILOG_DEFINES) > /dev/null 2>&1
	touch .elab.touchfile
	@echo "Elaboration done"

sim: .elab.touchfile
	@echo "Running simulation"
	xsim $(TOP) -tclbatch $(TCLBATCH) -testplusarg UVM_VERBOSITY=$(UVM_VERBOSITY) -testplusarg UVM_TESTNAME=$(UVM_TESTNAME) -sv_seed $(SEED) -stats -onerror quit -testplusarg EXIT_ON_ERROR -testplusarg $(FUNC_COV) -log test.log > /dev/null 2>&1
	touch .sim.touchfile
	@echo "Simulation done"

coverage: .sim.touchfile
	xcrg -cc_dir xsim.codeCov/work.top/ -report_format html

cleancov:
	rm -rf xcrg.log
	rm -rf xcrg_code_cov_report
	rm -rf xcrg_func_cov_report

# code coverage db is built during elab and populated during sim
clean: cleancov
	rm -rf .*touchfile
	rm -rf xsim.dir
	rm -rf *.log
	rm -rf *.jou
	rm -rf *.pb
	rm -rf xsim.covdb
	rm -rf xsim.codeCov

cleanall: clean
	rm -rf .Xil
	rm -rf *.wdb
	rm -rf *.so

.PHONY: all compile elab sim coverage clean cleanall cleancov
