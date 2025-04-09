#!/bin/bash
# Helper script to build tensor adapter libraries for PyTorch
set -euo pipefail

TORCH_BINDIR="${BINDIR}/tensoradapter/pytorch"
TORCH_SRCDIR="${SRCDIR}/tensoradapter/pytorch"
mkdir -p "${TORCH_BINDIR}/build"
cd "${TORCH_BINDIR}/build"

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
)
echo "TORCH CMake Flags: ${CMAKE_FLAGS[@]}"

if [ $# -eq 0 ]; then
    "${CMAKE_COMMAND}" "${CMAKE_FLAGS[@]}" "${TORCH_SRCDIR}"
    cmake --build .
    # CPSOURCE deliberately unquoted to expand wildcard
    cp -v ${CPSOURCE} "${TORCH_BINDIR}"
else
    for PYTHON_INTERP in "$@"; do
        TORCH_VER="$("${PYTHON_INTERP}" -c 'import torch; print(torch.__version__.split("+")[0])')"
        mkdir -p "${TORCH_VER}"
        cd "${TORCH_VER}"
        "${CMAKE_COMMAND}" "${CMAKE_FLAGS[@]}" -DPYTHON_INTERP="${PYTHON_INTERP}" "${TORCH_SRCDIR}"
        cmake --build .
        # CPSOURCE deliberately unquoted to expand wildcard
        cp -v ${CPSOURCE} "${TORCH_BINDIR}"
        cd ..
    done
fi
