import os
import subprocess
import datetime
import shutil
import argparse
import multiprocessing
import functools
import json

def parse_args():
    parser = argparse.ArgumentParser(description='Run RTL simulation.')
    parser.add_argument('-t', '--test', action='append', help='Specify the tests to run')
    parser.add_argument('--testlist', help='Path to a JSON file containing a list of tests')
    parser.add_argument('--rundir', help='Optional custom run directory name')
    parser.add_argument('--keep-build', action='store_true', help='Reuse existing build directory if available')
    parser.add_argument('-j', '--jobs', type=int, default=os.cpu_count(), help='Number of parallel jobs to run (default: number of CPU cores)')
    parser.add_argument('--coverage', action='store_true', help='Enable coverage analysis')
    return parser.parse_args()

def read_tests_from_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def validate_tests(tests, valid_tests):
    invalid_tests = [t for t in tests if t not in valid_tests]
    if invalid_tests:
        raise ValueError(f"Invalid tests specified: {', '.join(invalid_tests)}")
    return tests

def run_test(test_name, run_dir, build_dir):
    test_dir = os.path.join(run_dir, f"test_{test_name}")
    if os.path.exists(test_dir):
        shutil.rmtree(test_dir)
    shutil.copytree(build_dir, test_dir, symlinks=True)
    subprocess.run(["make", "sim", f"UVM_TESTNAME={test_name}"], cwd=test_dir)
    # write to test.status
    status_file_path = os.path.join(test_dir, "test.status")
    with open(status_file_path, 'w') as status_file:
        status = check_status(os.path.join(test_dir, "test.log"), test_name)
        status_file.write(status)
        print(status)

def check_status(test_log_path, test_name):
    if os.path.exists(test_log_path):
        with open(test_log_path, 'r') as file:
            for line in file:
                if "==== PASS ====" in line:
                    return f"Test {test_name} PASSED."
                elif "==== FAIL ====" in line:
                    return f"Test {test_name} FAILED."
            return f"Test {test_name} result is inconclusive. Check test.log for details."
    else:
        return f"test.log not found at {test_log_path}. Cannot determine test result."

def main():
    args = parse_args()

    if args.test and args.testlist:
        raise ValueError("Cannot use both -t|--test and --testlist. Choose one.")
    
    # check if the specified number of jobs exceeds the number of CPU cores
    if args.jobs < 1:
        raise ValueError("Error: The number of parallel jobs must be at least 1.")
    total_cores = os.cpu_count()
    if args.jobs > total_cores:
        print(f"Warning: The specified number of jobs ({args.jobs}) exceeds the number of available CPU cores ({total_cores}).")
    print(f"Running with {args.jobs} parallel jobs.")
    
    # load internal test list
    internal_testlist_path = os.path.join(os.path.dirname(__file__), "testlist.json")
    valid_tests = read_tests_from_json(internal_testlist_path)

    # determine the tests to run
    if args.testlist:
        testlist_path = args.testlist
        all_tests = validate_tests(read_tests_from_json(testlist_path), valid_tests)
    elif args.test:
        all_tests = validate_tests(args.test, valid_tests)
    else:
        raise ValueError("No tests specified. Please use -t|--test or --testlist to specify tests.")

    # handle run directory
    if args.rundir:
        run_dir = args.rundir
    else:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_dir = f"aes_test_{timestamp}"
    
    if not os.path.exists(run_dir):
        os.makedirs(run_dir)

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

        subprocess.run(["make", "elab"], cwd=build_dir)

    # run tests in parallel
    with multiprocessing.Pool(args.jobs) as pool:
        # create a partial function with fixed run_dir and build_dir
        partial_run_test = functools.partial(run_test, run_dir=run_dir, build_dir=build_dir)
        pool.map(partial_run_test, all_tests)
    
    # check test suite results
    all_tests_passed = True
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
            print(f"Status for {test_name} not found.")
            all_tests_passed = False
    if all_tests_passed:
        print("\nTest suite PASSED.\n")
    else:
        print("\nTest suite FAILED.\n")

    # coverage analysis
    if args.coverage:
        if not all_tests_passed:
            raise RuntimeError("Cannot perform coverage analysis when test suite failed.")
        # link Makefile in the rundir
        makefile_path = os.path.join(os.getcwd(), "Makefile")
        linked_makefile_path = os.path.join(run_dir, "Makefile")
        if not os.path.exists(linked_makefile_path):
            os.symlink(makefile_path, linked_makefile_path)
        else:
            subprocess.run(["make", "cleancov"], cwd=run_dir)

        # create cc_dirs arguments string
        cc_dirs = ' '.join([f"-cc_dir 'test_{test_name}'" for test_name in all_tests])
        fc_dirs = ' '.join([f"-dir 'test_{test_name}/xsim.covdb'" for test_name in all_tests])

        subprocess.run(["make", "code_cov_merge", f"CODE_COV_DB_ALL={cc_dirs}"], cwd=run_dir)
        subprocess.run(["make", "func_cov_merge", f"FUNC_COV_DB_ALL={fc_dirs}"], cwd=run_dir)

if __name__ == "__main__":
    main()
