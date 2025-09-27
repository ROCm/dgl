#!/usr/bin/env bash

set -exuo pipefail

################################################################################
# Setup and checks
################################################################################

# Assumptions:
# - LLVM toolchain is installed and is in the path (see https://apt.llvm.org/ for download instructions)
# - You've built DGL with coverage flags turned on using `cmake --preset rocm-cov`
# - You're running this inside of the build directory (it keeps the dgl root dir clean)

# Output:
# - coverage_report.txt

# Notes:
# - This coverage report omits third party libraries
# - This coverage report is only generated from the C++ tests. The python tests (which 
#   also call functions from libdgl.so) are not included.


SCRIPT_DIR=$(realpath $(dirname $0))
DGL_DIR=$(realpath ${SCRIPT_DIR}/..)

# Add warning if llvm-cov or llvm-profdata are not in the path
if ! command -v llvm-cov &> /dev/null; then
  echo "llvm-cov could not be found in the path"
  exit 1
fi
if ! command -v llvm-profdata &> /dev/null; then
  echo "llvm-profdata could not be found in the path"
  exit 1
fi

# Add warning if the build directory is not the current directory
if [ "$(pwd)" != "${DGL_DIR}/build" ]; then
  echo "[WARNING] You're not in the build directory"
fi

################################################################################
# Run tests
################################################################################

${DGL_DIR}/build/runUnitTests

################################################################################
# Generate coverage report
################################################################################

# TODO do we want to collect graphbolt coverage here if we are skipping other third party libraries?
BINARIES="${DGL_DIR}/build/libdgl.so ${DGL_DIR}/build/graphbolt/libgraphbolt_pytorch_2.6.0.so"

# Collect all the profraw files
find . -type f -name "*.profraw" > rawprofiles.list

# Merge the profraw files
llvm-profdata merge --sparse  --input-files=rawprofiles.list -o coverage.profdata

# Generate the coverage report
llvm-cov report ${BINARIES} -instr-profile=coverage.profdata --ignore-filename-regex="third_party*" | tee coverage_report.txt

# llvm-cov show --instr-profile=coverage.profdata --ignore-filename-regex="third_party*" --format=html --output-dir=cov_report_llvmcov ${BINARIES} 

# TODO this isn't working quite right yet
# llvm-cov show ${BINARIES} \
#   -instr-profile=coverage.profdata \
#   -show-line-counts-or-regions \
#   -format=html \
#   -output-dir=coverage_report
  