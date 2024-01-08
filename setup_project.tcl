
puts "Script should be run from Vivado TCL console"
puts "Script assumes that the project is already open and the current working directory is the project/repo directory."

# TODO: consider adding source files, possibly based on the script argument(s)

puts "Setting up Project settings"

# get defaults (seed and test) from shell script
set defaults [exec run_sim.sh -g]
set defaults_list [split $defaults ","]
set test [lindex $defaults_list 0]
set seed [lindex $defaults_list 1]

# compilation
set_property -name {xsim.compile.tcl.pre} -value {pre_compile.tcl} -objects [get_filesets sim_1]
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
# compilation Verilog options
# optional, used for AES keys atm
set_property verilog_define {HIER_ACCESS} [get_filesets sim_1]

# elaboration
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm -sv_lib aes_dpi.so} -objects [get_filesets sim_1]

# simulation
set xsim_opts "-testplusarg UVM_VERBOSITY=UVM_HIGH -testplusarg UVM_TESTNAME=$test -sv_seed $seed"
set_property -name {xsim.simulate.xsim.more_options} -value $xsim_opts -objects [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]

# Use all available threads for compilation and elaboration
set_property -name {xsim.compile.xsc.mt_level} -value {8} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xsc.mt_level} -value {8} -objects [get_filesets sim_1]

puts "Setting up Project settings finished"
