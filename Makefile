TOP := top
SOURCE_FILES_SV := $(REPO_ROOT)/sources_sv.f
SOURCE_FILES_VHD := $(REPO_ROOT)/sources_vhd.f
VERILOG_DEFINES := -d HIER_ACCESS -d VIVADO_RND_WORKAROUND
COMP_OPTS_SV := -sv --incr --relax  -L uvm -L uvm
COMP_OPTS_VHD := --incr --relax
DPI_ROOT := $(REPO_ROOT)/aes-256_model
DPI_SRCS := $(DPI_ROOT)/aes.c $(DPI_ROOT)/aes_dpi.c
DPI_OUT := aes_dpi.so
DPI_LOG := aes_dpi.log
ELAB_DEBUG := typical
ELAB_OPTS := -debug $(ELAB_DEBUG) --incr --relax -L uvm -sv_lib $(DPI_OUT) -cc_type t --mt 8
SIM_PLUSARGS :=
REF_VECTORS_PATH := $(REPO_ROOT)/ref_vectors
REF_VECTORS := vectors_base.csv

TCLBATCH := $(REPO_ROOT)/run_cfg.tcl
UVM_VERBOSITY := UVM_LOW
UVM_TESTNAME := aes256_test_smoke
SEED := 10
FUNC_COV := FUNC_COVERAGE

CODE_COV_DB_PATH := xsim.codeCov/work.top
CODE_COV_DB_ALL := -cc_dir $(CODE_COV_DB_PATH)
FUNC_COV_DB_PATH := xsim.covdb/work.top
FUNC_COV_DB_ALL := -dir $(FUNC_COV_DB_PATH)

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
	@touch .compile.touchfile
	@echo "RTL compilation done"

elab: .elab.touchfile
.elab.touchfile: .compile.touchfile $(DPI_OUT)
	@echo "Elaborating design"
	xelab $(TOP) $(ELAB_OPTS) $(VERILOG_DEFINES) > /dev/null 2>&1
	@touch .elab.touchfile
	@echo "Elaboration done"

sim: .elab.touchfile
	@echo "Running simulation"
	xsim $(TOP) -tclbatch $(TCLBATCH) -testplusarg UVM_VERBOSITY=$(UVM_VERBOSITY) -testplusarg UVM_TESTNAME=$(UVM_TESTNAME) -sv_seed $(SEED) -stats -onerror quit -testplusarg EXIT_ON_ERROR -testplusarg $(FUNC_COV) $(SIM_PLUSARGS) -log test.log > /dev/null 2>&1
	@touch .sim.touchfile
	@echo "Simulation done"
	@grep "PASS\|FAIL" test.log

sim_vec:
	$(MAKE) sim UVM_TESTNAME=aes256_test_ref_vectors SIM_PLUSARGS='-testplusarg ref_vectors_path=$(REF_VECTORS_PATH)/$(REF_VECTORS)'

coverage:
	xcrg -cc_dir $(CODE_COV_DB_PATH) -report_format html -dir $(FUNC_COV_DB_PATH) 

code_cov_merge:
	xcrg -merge_cc -cc_db work.top $(CODE_COV_DB_ALL) -log xcrg_cc.log > /dev/null 2>&1

func_cov_merge:
	xcrg $(FUNC_COV_DB_ALL) -log xcrg_fc.log > /dev/null 2>&1

cleancov:
	rm -rf xcrg.log
	rm -rf xcrg_cc.log
	rm -rf xcrg_fc.log
	rm -rf xcrg_code_cov_report
	rm -rf xcrg_func_cov_report
	rm -rf xsim.codeCov/xcrg_merged
	rm -rf xsim.covdb/xcrg_mdb

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
