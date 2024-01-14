TOP := top
SOURCE_FILES_SV := $(REPO_ROOT)/sources_sv.f
SOURCE_FILES_VHD := $(REPO_ROOT)/sources_vhd.f
VERILOG_DEFINES := -d HIER_ACCESS
COMP_OPTS_SV := -sv --incr --relax  -L uvm -L uvm
COMP_OPTS_VHD := --incr --relax
DPI_ROOT := $(REPO_ROOT)/aes-256_model
DPI_SRCS := $(DPI_ROOT)/aes.c $(DPI_ROOT)/aes_dpi.c
DPI_OUT := aes_dpi.so
ELAB_OPTS := -debug typical --incr --relax -L uvm -sv_lib $(DPI_OUT) -cc_type t --mt 8

TCLBATCH := $(REPO_ROOT)/run_cfg.tcl
UVM_VERBOSITY := UVM_LOW
UVM_TESTNAME := aes256_test_smoke
SEED := 10
FUNC_COV := FUNC_COVERAGE

all: sim

$(DPI_OUT): $(DPI_SRCS)
	xsc $(DPI_SRCS) -o $(DPI_OUT)

compile: .compile.touchfile
.compile.touchfile:
	xvlog $(COMP_OPTS_SV) -prj $(SOURCE_FILES_SV) $(VERILOG_DEFINES)
	xvhdl $(COMP_OPTS_VHD) -prj $(SOURCE_FILES_VHD)
	touch .compile.touchfile

elab: .elab.touchfile
.elab.touchfile: .compile.touchfile $(DPI_OUT)
	xelab $(TOP) $(ELAB_OPTS) $(VERILOG_DEFINES)
	touch .elab.touchfile

sim: .elab.touchfile
	xsim $(TOP) -tclbatch $(TCLBATCH) -testplusarg UVM_VERBOSITY=$(UVM_VERBOSITY) -testplusarg UVM_TESTNAME=$(UVM_TESTNAME) -sv_seed $(SEED) -stats -onerror quit -testplusarg EXIT_ON_ERROR -testplusarg $(FUNC_COV) -log test.log
	touch .sim.touchfile

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
