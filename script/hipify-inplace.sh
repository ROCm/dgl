#!/bin/bash

# Hipifies the DGL codebase. That is, translates CUDA terminology to HIP, using
# the HIPIFY tooling (https://rocm.docs.amd.com/projects/HIPIFY/) plus some
# custom regex replacements. This performs the hipification inplace, saving the
# original files with a .prehip extension and then modifying the existing files
# without renaming them. This means HIP files will have cuda file extensions
# (e.g. .cu), so some tooling will need to be modified to work with this (e.g.
# set language mode in CMake). The advantage is that file path references like
# include statements don't need to change.

set -euo pipefail
DGL_HOME=$(dirname $(dirname $(realpath $0)))
cd "${DGL_HOME}"

LOG_DIR="$(mktemp --tmpdir -d hipify-inplace-XXXX)"
COMBINED_LOG="${LOG_DIR}/hipify-combined.log"

echo "Writing logs to ${LOG_DIR}"

function find_code() {
    find $@ -type f -name '*.cu' -o -name '*.CU'
    find $@ -type f -name '*.cpp' -o -name '*.cxx' -o -name '*.c' -o -name '*.cc'
    find $@ -type f -name '*.CPP' -o -name '*.CXX' -o -name '*.C' -o -name '*.CC'
    find $@ -type f -name '*.cuh' -o -name '*.CUH'
    find $@ -type f -name '*.h' -o -name '*.hpp' -o -name '*.inc' -o -name '*.inl' -o -name '*.hxx' -o -name '*.hdl'
    find $@ -type f -name '*.H' -o -name '*.HPP' -o -name '*.INC' -o -name '*.INL' -o -name '*.HXX' -o -name '*.HDL'
}

# There isn't any direct cuda code in the tests, but we still want to run our
# own sed replacements and want a prehip file for what they were before.
declare -a hipify_perl_srcs=(
    $(find_code third_party/HugeCTR/gpu_cache)
)

# Create a second array including the hipify-torch-extension.py targeted directories.
declare -a all_srcs=(
    ${hipify_perl_srcs[@]} $(find_code graphbolt)
)

echo "Starting hipify jobs"
declare -a log_files=()

# log_file="$(mktemp --tmpdir="${LOG_DIR}" hipify_graphbolt.XXX.log)"
# log_files+=("${log_file}")
# ( set -x ; script/hipify-torch-extension.py ${DGL_HOME}/graphbolt/ ) &> "${log_file}" &

for src in ${hipify_perl_srcs[@]}; do
    log_file="$(mktemp --tmpdir="${LOG_DIR}" hipify_${src//\//_}.XXX.log)"
    log_files+=("${log_file}")
    ( set -x ; hipify-perl -print-stats -inplace $src ) &> "${log_file}" &
done

echo "Waiting for hipify jobs to complete"
wait

# Using tail will print a separator between each file's contents.
tail -n +1 "${log_files[@]}" > "${COMBINED_LOG}"
echo "" >> "${COMBINED_LOG}"
echo "Combined logs written to ${COMBINED_LOG}"

# Additional fixes for project-specific things and things hipify misses or gets
# wrong.
echo "Running additional sed replacements"
for src in ${all_srcs[@]}; do
    sed -i -f - $src <<-EOF
        s@#include <hipblas.h>@#include <hipblas/hipblas.h>@
        s@#include <hipsparse.h>@#include <hipsparse/hipsparse.h>@
        s@#include <cuda_fp8.h>@#include <hip/hip_fp8.h>@
        s@#include <cuda_bf16.h>@#include <hip/hip_bf16.h>@
        s@#include <cub/cub.cuh>@#include <hipcub/hipcub.hpp>@
        s@#include "hip/extension/@#include "./cuda/extension/@
        s@#include "hip/cooperative_minibatching_utils.h"@#include "./cuda/cooperative_minibatching_utils.h"@
        s@#include "hip/max_uva_threads.h"@#include "./cuda/max_uva_threads.h"@
        s@\.\./hip/@@
        s@\bDeviceFor::Bulk\b@Bulk@g
        s@\bcub::@hipcub::@g
        s@\bcuda::stream_ref@cuco::cuda_stream_ref@
        s@\bcuda::::min@min@
        s@\bcuda::proclaim_return_type@proclaim_return_type@
        s@\bDGL_USE_CUDA\b@DGL_USE_ROCM@g
        s@\bGRAPHBOLT_USE_CUDA\b@GRAPHBOLT_USE_ROCM@g
        s@\bCUB_VERSION\b@HIPCUB_VERSION@g
        s@\bCUDART_ZERO_BF16\b@HIPRT_ZERO_BF16@g
        s@\bCUDART_INF_BF16\b@HIPRT_INF_BF16@g
        s@\bthrust::cuda::par@thrust::hip::par@g
        s@\b__nv_fp8_e4m3\b@__hip_fp8_e4m3@g
        s@\b__nv_fp8_e5m2\b@__hip_fp8_e5m2@g
        s@\bCUBLAS_GEMM_DEFAULT_TENSOR_OP\b@HIPBLAS_GEMM_DEFAULT@g
        s@\bcurand4\b@hiprand4@g
        s@\bhip_bfloat16\b@__hip_bfloat16@g # hipify uses the old one
        s@\bnv_bfloat16\b@hip_bfloat16@g # For some reason, some graphbolt dependencies need the old version
        s@\b__trap();@abort();@
EOF

    # If no changes were made, delete the prehip file.
    if cmp -s "${src}" "${src}.prehip"; then
        echo "Deleting unchanged ${src}.prehip" >> "${COMBINED_LOG}"
        rm "${src}.prehip"
    fi
done
