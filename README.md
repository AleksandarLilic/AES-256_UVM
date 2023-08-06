# AES-256 UVM tesbench

UVM testbench for AES-256 VHDL design

## Notes for setup in Xilinx Vivado 2022.1

Set `uvm` option for elaboration and compile steps (default UVM version is 1.2)
``` 
set_property −name {xsim.elaborate.xelab.more_options} −value {−L uvm} −objects [get_filesets sim_1] 
set_property −name {xsim.compile.xvlog.more_options} −value {−L uvm} −objects [get_filesets sim_1]
```

Set up level of verbosity, as needed
```
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_VERBOSITY=UVM_HIGH} -objects [get_filesets sim_1]
```

Set test name if required, `basic_test` as an example
```
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TESTNAME=basic_test} -objects [get_filesets sim_1]
```

## UVM Example
To get started, there is `simple_uvm_bench` directory that contains:
1. SystemVerilog adder design with interface and clocking block
2. VHDL implementation of the same adder
3. ``` `define``` for choosing between VHDL and SystemVerilog implementation 
4. Barebones UVM testbench 
