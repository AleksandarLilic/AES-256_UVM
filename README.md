# AES-256 UVM tesbench

UVM testbench for AES-256 VHDL design

# Running tests
## Environment and tools
System requirements:
1. Linux-based OS (tested on Ubuntu 22.04)
2. AMD Vivado 2023.2
3. GNU Make (tested with GNU Make 4.3)
4. Python 3.6+ (tested on Python 3.10)

## Make-based flow
Make provides recipes used to build and simulate the testbench, as well as for generating coverage reports. By running `make sim`, makefile goes through four steps:
1. Compile of the DUT and the testbench
2. Compile of the C model into a shared library
3. Elaborate of the previously compiled DUT and testbench, and linking the model shared library
4. Simulation for the specified test name

By default, `make sim` runs smoke test, though this can be changed by overriding the make variable `UVM_TESTNAME` to any of the supported tests. UVM verbosity is also exposed through `UVM_VERBOSITY` variable. Alternatively, running `make sim_vec` would use the reference vectors test, by default supplying the base vectors, specified through make variable `REF_VECTORS`. Make recipe `coverage` is provided to generate the report when only one functional and one code coverage databases exist. If multiple tests are run, and therefore multiple code and multiple functional coverage databases are generated, `code_cov_merge` and `func_cov_merge` should be used. These two recipes merge all specified databases (each one accepts only its respective database type) and generate a final coverage report for each coverage type.

## Test suite
Test suite, implemented as a python script, provides a straightforward method for dealing with multiple tests at once. By using the make-base flow, test suite handles:
1. Building a design snapshot
2. Running each of the specified tests in parallel (up to the max number of allowed workers) while reusing one common design snapshot
3. Checking of pass/fail status of each test
4. Generating coverage reports from all tests
The only required argument is which test(s) should be run. Test selection can be done in multiple ways:
1. single test: `-t TEST, --test TEST`
2. test(s) via JSON test list: `--testlist TESTLIST`
3. single vector test: `-v REF_VECTORS, --ref-vectors REF_VECTORS`
4. vector test(s) via JSON test list: `--ref-vectors-list REF_VECTORS_LIST`

JSON test lists have priority over a single test arguments. Regular tests and vector tests can be specified at the same time. All arguments and their descriptions are available with `-h` or `-–help`. Script uses two internal JSON files (one for regular tests, one for reference vectors) to check if the specified test is supported by the testbench. 

### Example commands
Run single test  
```
python3 run_test.py -t aes256_test_smoke
```

Run single test with run directory
```
python3 run_test.py -t aes256_test_smoke --rundir aestest
```

Run single test with run directory and keep build (if already built with previous script call, it will not build
again)
```
python3 run_test.py -t aes256_test_smoke --rundir aestest -–keep-build
```

Use JSON testlist instead of a single test
```
python3 run_test.py --testlist testlist.json --rundir aestest
```

Use JSON testlist and generate coverage
```
python3 run_test.py --testlist testlist.json --rundir aestest --coverage
```

Use testlist for ref vectors and generate coverage reports
```
python3 run_test.py --ref-vectors-testlist ref_vectors/ref_vectors_test.json --rundir aestest --coverage
```

Use testlist for regular tests, use separate testlist for reference vectors, and generate coverage reports
```
python3 run_test.py --testlist testlist.json --ref-vectors-testlist ref_vectors/ref_vectors_testlist.json --rundir aestest --coverage
```

Run only MCT reference vectors with previously built snapshot and run with 1 job to avoid running out of memory
```
python3 run_test.py --ref-vectors-testlist ref_vectors/ref_vectors_MCT.json --rundir aestest --keep-build --jobs 1
```

Generate coverage reports only for specified tests in the testlists
```
python3 run_test.py --testlist testlist.json --ref-vectors-testlist ref_vectors/ref_vectors.json --rundir aestest --coverage-only
```

# UVM Example
To get started, there is a `simple_uvm_bench` directory that contains:
1. SystemVerilog adder design with interface and clocking block
2. VHDL implementation of the same adder
3. ``` `define``` for choosing between VHDL and SystemVerilog implementation 
4. Barebones UVM testbench 
