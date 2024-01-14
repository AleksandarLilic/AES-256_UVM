#!/bin/bash
set -Eeuo pipefail
trap "echo -e \"\n\nERROR: Command failed at line: \${LINENO}.\n\n\"" ERR

DEFAULT_TEST_NAME="aes256_test"
DEFAULT_SEED=10
test_name=""
seed=""
collect_coverage=false
get_defaults=false
while getopts "t:s:cg" option; do
case "${option}" in
    t) test_name=${OPTARG};;
    s) seed=${OPTARG};;
    c) collect_coverage=true;;
    g) get_defaults=true;;
    *) echo "Usage: run_sim.sh [-t <test_name>] [-s <seed>]"; exit 1;;
esac
done

if [[ $get_defaults == true ]]; then
    echo "$DEFAULT_TEST_NAME,$DEFAULT_SEED"
    exit 0
fi

if [[ -z "$test_name" ]]; then
    echo "Test name not specified, using default test: <$DEFAULT_TEST_NAME>"
    test_name="$DEFAULT_TEST_NAME"
fi

if [[ -z $seed ]]; then
    echo "Seed not specified, using default seed: <$DEFAULT_SEED>"
    seed=$DEFAULT_SEED
fi

cov_arg=""
if [[ $collect_coverage == true ]]; then cov_arg="-testplusarg COVERAGE"; fi
sim_args="-testplusarg UVM_VERBOSITY=UVM_LOW -testplusarg UVM_TESTNAME=$test_name -sv_seed $seed -testplusarg EXIT_ON_ERROR $cov_arg"
sim_options="-onerror quit"
tcl_opts="-tclbatch ../../../../run_cfg.tcl"
tool_options="-stats"

xsim top_behav -key "{Behavioral:sim_1:Functional:top}" -log simulate.log $tcl_opts $sim_args $sim_options $tool_options

echo "Simulation finished"
