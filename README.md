# AES-256 UVM tesbench

UVM testbench for AES-256 VHDL design

## Notes for setup in Xilinx Vivado 2023.2

### UVM setup
Set `uvm` option for elaboration and compile steps (default UVM version is 1.2)
``` 
set_property −name {xsim.elaborate.xelab.more_options} −value {−L uvm} −objects [get_filesets sim_1] 
```
```
set_property −name {xsim.compile.xvlog.more_options} −value {−L uvm} −objects [get_filesets sim_1]
```
### Simulation options
> [!TIP]  
> Change of simulation option(s) doesn't require recompile, just new simulation

Set up level of verbosity, as needed
```
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_VERBOSITY=UVM_HIGH} -objects [get_filesets sim_1]
```

Set test name if required (e.g. to select between multiple tests), `basic_test` as an example
```
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TESTNAME=basic_test} -objects [get_filesets sim_1]
```

Set seed for repeatability 
```
set_property -name {xsim.simulate.xsim.more_options} -value {-sv_seed 12345} -objects [get_filesets sim_1]
```

All three options at the same time as a single tcl list passed to the `-value` argument
```
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_VERBOSITY=UVM_HIGH -testplusarg UVM_TESTNAME=basic_test -sv_seed 12345} -objects [get_filesets sim_1]
```

Set simulation time to 100us. It will either run for 100us (and pause there) or exit when `$finish`ed from the test, whichever comes first
```
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]
```

### Use all available CPU threads
Increase multithreading to 8 threads (speeds up some parts of the compilation/elaboration)
```
set_property -name {xsim.compile.xsc.mt_level} -value {8} -objects [get_filesets sim_1]
```
```
set_property -name {xsim.elaborate.mt_level} -value {8} -objects [get_filesets sim_1]
```

## UVM Example
To get started, there is a `simple_uvm_bench` directory that contains:
1. SystemVerilog adder design with interface and clocking block
2. VHDL implementation of the same adder
3. ``` `define``` for choosing between VHDL and SystemVerilog implementation 
4. Barebones UVM testbench 
