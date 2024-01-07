#!/bin/bash -x
set -Eeuo pipefail
trap "echo -e \"\n\nERROR: Command failed at line: \${LINENO}.\n\n\"" ERR

default_test_name="aes256_test"
default_seed=10
test_name=""
seed=""
while getopts "t:s:" option; do
case "${option}" in
    t) test_name=${OPTARG};;
    s) seed=${OPTARG};;
    *) echo "Usage: run_sim.sh [-t <test_name>] [-s <seed>]"; exit 1;;
esac
done

if [[ -z "$test_name" ]]; then
    echo "Test name not specified, using default test: <$default_test_name>"
    test_name="$default_test_name"
fi

if [[ -z $seed ]]; then
    echo "Seed not specified, using default seed: <$default_seed>"
    seed=$default_seed
fi

sim_args="-testplusarg UVM_VERBOSITY=UVM_LOW -testplusarg UVM_TESTNAME=$test_name -sv_seed $seed -testplusarg EXIT_ON_ERROR"
sim_options="--runall -onerror quit"
tool_options="-stats"

xsim top_behav -key "{Behavioral:sim_1:Functional:top}" -log simulate.log $sim_args $sim_options $tool_options

echo "Simulation finished"
