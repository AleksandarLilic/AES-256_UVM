#!/bin/bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
export REPO_ROOT

echo "REPO_ROOT=$REPO_ROOT"
echo "Also source Vivado settings script: '.settings64-Vivado.sh'"
