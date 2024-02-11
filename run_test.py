import os
import subprocess
import datetime
import shutil
import argparse
import multiprocessing
import functools
import json
import random

RUN_CFG = "run_cfg_suite.tcl"

def parse_args():
    parser = argparse.ArgumentParser(description='Run RTL simulation.')
    parser.add_argument('-t', '--test', action='append', help='Specify the tests to run')
    parser.add_argument('--testlist', help='Path to a JSON file containing a list of tests')
    parser.add_argument('--rundir', help='Optional custom run directory name')
    parser.add_argument('--keep-build', action='store_true', help='Reuse existing build directory if available')
    parser.add_argument('-j', '--jobs', type=int, default=MAX_WORKERS, help='Number of parallel jobs to run (default: number of CPU cores)')
    parser.add_argument('--coverage', action='store_true', help='Enable coverage analysis')
    parser.add_argument('--coverage-only', action='store_true', help='Only run coverage analysis. Relies on the existing test directories for the specified tests')
    parser.add_argument('--seed', type=int, help='Seed value for the tests')
    parser.add_argument('-v', '--ref-vectors', help='Specify name of the reference vector to run')
    parser.add_argument('--ref-vectors-testlist', help='Path to a JSON file containing test name and a list of reference vectors')
    parser.add_argument('--log_wave', action='store_true', help='Include log wave command in TCL script')
    return parser.parse_args()

def create_run_cfg(add_log_wave):
    tcl_content = []
    if add_log_wave:
        tcl_content.append("log_wave -recursive *")
    tcl_content.extend([
        "run all",
        "exit"
    ])

    with open(RUN_CFG, 'w') as file:
        file.writelines(line + '\n' for line in tcl_content)

def read_from_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def validate_list(specified_list, valid_list):
    invalid_list_elements = [lst for lst in specified_list if lst not in valid_list]
    if invalid_list_elements:
        raise ValueError(f"Invalid elements specified: {', '.join(invalid_list_elements)}")
    return specified_list

def get_ref_vectors_testlist(vec):
    return [v for v in vec['vectors'].keys()]

def run_test(test_name, run_dir, build_dir, ref_vectors_test, ref_vectors_dict={}, sv_seed=11):
    test_dir = os.path.join(run_dir, f"test_{test_name}")
    if os.path.exists(test_dir):
        shutil.rmtree(test_dir)
    shutil.copytree(build_dir, test_dir, symlinks=True)
    if ref_vectors_test != None and ref_vectors_test in test_name:
        # running ref vector test
        ref_vectors = test_name.replace(ref_vectors_test + "_", "")
        user_settings = f"USER_SETTINGS={ref_vectors_dict[ref_vectors]}"
        make_status = subprocess.run(["make", "sim_vec", 
                                      f"UVM_TESTNAME={ref_vectors_test}",
                                      f"REF_VECTORS={ref_vectors}.csv",
                                      f"TCLBATCH={RUN_CFG}",
                                      f"{user_settings}"], 
                                      cwd=test_dir)        
    else:
        # running regular test
        make_status = subprocess.run(["make", "sim",
                                      f"UVM_TESTNAME={test_name}",
                                      f"TCLBATCH={RUN_CFG}",
                                      f"SEED={sv_seed}"],
                                      cwd=test_dir)
    
    print(f"Test {test_name} DONE.")
    check_make_status(make_status, f"run test {test_name}")
    # write to test.status
    status_file_path = os.path.join(test_dir, "test.status")
    with open(status_file_path, 'w') as status_file:
        status = check_test_status(os.path.join(test_dir, "test.log"), test_name)
        status_file.write(status)
        print(status)

def check_make_status(make_status, msg: str):
    if make_status.returncode != 0:
        raise RuntimeError(f"Error: Makefile failed to {msg}.")

def check_test_status(test_log_path, test_name):
    if os.path.exists(test_log_path):
        with open(test_log_path, 'r') as file:
            for line in file:
                if "==== PASS ====" in line:
                    return f"Test {test_name} PASSED."
                elif "==== FAIL ====" in line:
                    return f"Test {test_name} FAILED."
            return f"Test {test_name} result is inconclusive. Check {test_log_path} for details."
    else:
        return f"test.log not found at {test_log_path}. Cannot determine test result."

def main():
    start_time = datetime.datetime.now()
    args = parse_args()

    # check arguments
    if args.test and args.testlist:
        raise ValueError("Cannot use both -t|--test and --testlist. Choose one.")
    if args.test and args.ref_vectors:
        raise ValueError("Cannot use both -t|--test and -v|--ref-vectors. Vector test is specified in the JOSN config file.")
    if args.testlist and args.ref_vectors:
        raise ValueError("Cannot use both --testlist and -v|--ref-vectors. Single reference vector cannot be used with a test list. Specify one test in the JSON ref_vectors config file if needed.")
    if args.coverage_only and args.coverage:
        raise ValueError("Cannot use both --coverage-only and --coverage. Choose one.")
    
    # create run_cfg.tcl
    create_run_cfg(args.log_wave)
    
    # load internal test list
    internal_testlist_path = os.path.join(os.path.dirname(__file__), "testlist.json")
    valid_tests = read_from_json(internal_testlist_path)

    # determine the tests to run
    all_tests = []
    if args.testlist:
        testlist_path = args.testlist
        all_tests = validate_list(read_from_json(testlist_path), valid_tests)
    elif args.test:
        all_tests = validate_list(args.test, valid_tests)
    elif not (args.ref_vectors_testlist or args.ref_vectors):
        raise ValueError("No tests specified. Please use -t|--test or --testlist to specify tests.")
    
    # load internal reference vector list
    internal_ref_vectors_config_path = os.path.join(os.path.dirname(__file__), "ref_vectors/ref_vectors.json")
    valid_ref_vectors = read_from_json(internal_ref_vectors_config_path)
    
    ref_vectors_test = valid_ref_vectors["test_name"]
    ref_vectors_config = {} 
    if args.ref_vectors_testlist:
        ref_vectors_config = read_from_json(args.ref_vectors_testlist)
        all_ref_vectors = validate_list(get_ref_vectors_testlist(ref_vectors_config), get_ref_vectors_testlist(valid_ref_vectors))
        all_vector_tests = [ref_vectors_test + "_" + ref_vector for ref_vector in all_ref_vectors]
        all_tests = all_tests + all_vector_tests
    elif args.ref_vectors:
        all_ref_vectors = validate_list([args.ref_vectors], get_ref_vectors_testlist(valid_ref_vectors))
        all_vector_tests = [ref_vectors_test + "_" + ref_vector for ref_vector in all_ref_vectors]
        all_tests = all_vector_tests
    elif not (args.testlist or args.test):
        raise ValueError("No reference vectors specified. Please use -v|--ref-vectors or --ref-vectors-testlist to specify reference vectors.")
    else:
        ref_vectors_test = None

    print(f"\nRunning {len(all_tests)} tests:")
    for t in all_tests:
        print("   ",t)
    print()
    
    # handle run directory
    if args.rundir:
        run_dir = args.rundir
    else:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_dir = f"aes_test_{timestamp}"
    
    if not os.path.exists(run_dir):
        os.makedirs(run_dir)

    if not args.coverage_only:
        # handle build directory and build if necessary
        build_dir = os.path.join(run_dir, "build")
        if args.keep_build and os.path.exists(f"{build_dir}/.elab.touchfile"):
            print(f"Reusing existing build directory at <{build_dir}>")
        else:
            if os.path.exists(build_dir):
                shutil.rmtree(build_dir)
            os.makedirs(build_dir)
            makefile_path = os.path.join(os.getcwd(), "Makefile")
            linked_makefile_path = os.path.join(build_dir, "Makefile")
            os.symlink(makefile_path, linked_makefile_path)

            make_status = subprocess.run(["make", "elab"], cwd=build_dir)
            check_make_status(make_status, "build")

    # check if the specified number of jobs exceeds the number of CPU cores
    if args.jobs < 1:
        raise ValueError("Error: The number of parallel jobs must be at least 1.")
    if args.jobs > MAX_WORKERS:
        print(f"Warning: The specified number of jobs ({args.jobs}) exceeds the number of available CPU cores ({MAX_WORKERS}).")
    print(f"Running simulation with {min(args.jobs,MAX_WORKERS)} parallel jobs.")
    
    if not args.coverage_only:
        # run tests in parallel
        random.seed(5)
        sv_seed = args.seed if args.seed is not None else random.randint(0, 2**32 - 1)
        with multiprocessing.Pool(min(args.jobs,MAX_WORKERS)) as pool:
            # create a partial function with all fixed arguments except test_name
            partial_run_test = functools.partial(run_test, run_dir=run_dir, build_dir=build_dir,
                                                ref_vectors_test=ref_vectors_test, sv_seed=sv_seed,
                                                ref_vectors_dict=ref_vectors_config.get('vectors', None))
            pool.map(partial_run_test, all_tests)
    
    # check test suite results
    all_tests_passed = True
    tests_num = len(all_tests)
    tests_passed = 0
    print("\nSummary:")
    for test_name in all_tests:
        test_dir = os.path.join(run_dir, f"test_{test_name}")
        status_file_path = os.path.join(test_dir, "test.status")
        if os.path.exists(status_file_path):
            with open(status_file_path, 'r') as status_file:
                status = status_file.read()
                print(status)
                if "PASSED" not in status:
                    all_tests_passed = False
                else:
                    tests_passed += 1
        else:
            print(f"Status for {test_name} not found.")
            all_tests_passed = False
    
    print(f"\nTest suite DONE. Pass rate: {tests_passed}/{tests_num} passed")
    if all_tests_passed:
        print("\nTest suite PASSED.\n")
    else:
        print("\nTest suite FAILED.\n")

    # coverage analysis
    if args.coverage or args.coverage_only:
        if not all_tests_passed:
            raise RuntimeError("Cannot perform coverage analysis when test suite failed.")
        # link Makefile in the rundir
        makefile_path = os.path.join(os.getcwd(), "Makefile")
        linked_makefile_path = os.path.join(run_dir, "Makefile")
        if not os.path.exists(linked_makefile_path):
            os.symlink(makefile_path, linked_makefile_path)
        else:
            make_status = subprocess.run(["make", "cleancov"], cwd=run_dir)
            check_make_status(make_status, "clean coverage databases")
        
        # create cc_dirs arguments string
        cc_dirs = ' '.join([f"-cc_dir 'test_{test_name}'" for test_name in all_tests])
        fc_dirs = ' '.join([f"-dir 'test_{test_name}/xsim.covdb'" for test_name in all_tests])

        make_status = subprocess.run(["make", "code_cov_merge", f"CODE_COV_DB_ALL={cc_dirs}"], cwd=run_dir)
        check_make_status(make_status, "merge code coverage databases")
        make_status = subprocess.run(["make", "func_cov_merge", f"FUNC_COV_DB_ALL={fc_dirs}"], cwd=run_dir)
        check_make_status(make_status, "merge functional coverage databases")

        print("\nCoverage analysis DONE.\n")
    
    end_time = datetime.datetime.now()
    elapsed_time = end_time - start_time
    hours, remainder = divmod(elapsed_time.seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    
    print("Test suite runtime:")
    if hours:
        print(f"Runtime: {hours}h {minutes}m {seconds}s")
    else:
        print(f"Runtime: {minutes}m {seconds}s")
    print()

if __name__ == "__main__":
    MAX_WORKERS = int(os.cpu_count()/2) # most likely 1C/2T, fastest simulation as measured
    main()
