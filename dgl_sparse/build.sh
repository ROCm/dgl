#!/bin/bash
# Helper script to build dgl sparse libraries for PyTorch
set -euo pipefail

SPARSE_BINDIR="${BINDIR}/dgl_sparse"
SPARSE_SRCDIR="${SRCDIR}/dgl_sparse"
mkdir -p "${SPARSE_BINDIR}/build"
cd "${SPARSE_BINDIR}/build"

if [ $(uname) = 'Darwin' ]; then
    CPSOURCE=*.dylib
else
    CPSOURCE=*.so
fi

declare -a CMAKE_FLAGS=(
    "-G${GENERATOR}"
    "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
    "-DCUDA_TOOLKIT_ROOT_DIR=${CUDA_TOOLKIT_ROOT_DIR}"
    "-DTORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-}"
    "-DUSE_CUDA=${USE_CUDA}"
    "-DUSE_ROCM=${USE_ROCM}"
    "-DGPU_TARGETS=${GPU_TARGETS:-}"
    "-DAMDGPU_TARGETS=${AMDGPU_TARGETS:-}"
    "-DCMAKE_HIP_ARCHITECTURES=${CMAKE_HIP_ARCHITECTURES:-}"
    "-DEXTERNAL_DMLC_LIB_PATH=${EXTERNAL_DMLC_LIB_PATH:-}"
    # CMake passes in the list of directories separated by spaces.  Here we
    # replace them with semicolons.
    "-DDGL_INCLUDE_DIRS=${INCLUDEDIR// /;}"
    "-DDGL_BUILD_DIR=${BINDIR}"
)
echo "DGL Sparse CMAKE_FLAGS: ${CMAKE_FLAGS[@]}"

if [ $# -eq 0 ]; then
    "${CMAKE_COMMAND}" "${CMAKE_FLAGS[@]}" "${SPARSE_SRCDIR}"
    cmake --build .
    # CPSOURCE deliberately unquoted to expand wildcard
    cp -v ${CPSOURCE} "${SPARSE_BINDIR}"
else
    for PYTHON_INTERP in "$@"; do
        TORCH_VER="$("${PYTHON_INTERP}" -c 'import torch; print(torch.__version__.split("+")[0])')"
        mkdir -p "${TORCH_VER}"
        cd "${TORCH_VER}"
        "${CMAKE_COMMAND}" "${CMAKE_FLAGS[@]}" -DPYTHON_INTERP="${PYTHON_INTERP}" "${SPARSE_SRCDIR}"
        cmake --build .
        # CPSOURCE deliberately unquoted to expand wildcard
        cp -v ${CPSOURCE} "${SPARSE_BINDIR}"
        cd ..
    done
fi
