#!/bin/bash
# Helper script to build graphbolt libraries for PyTorch
set -euo pipefail
GRAPHBOLT_BINDIR="${BINDIR}/graphbolt"
GRAPHBOLT_SRCDIR="${SRCDIR}/graphbolt"
mkdir -p "${GRAPHBOLT_BINDIR}/build"
cd "${GRAPHBOLT_BINDIR}/build"

if [ $(uname) = 'Darwin' ]; then
  CPSOURCE=*.dylib
else
  CPSOURCE=*.so
fi

# We build for the same architectures as DGL, thus we hardcode
# TORCH_CUDA_ARCH_LIST and we need to at least compile for Volta. Until
# https://github.com/NVIDIA/cccl/issues/1083 is resolved, we need to compile the
# cuda/extension folder with Volta+ CUDA architectures.
TORCH_CUDA_ARCH_LIST="Volta"
if ! [[ -z "${CUDAARCHS}" ]]; then
  # The architecture list is passed as an environment variable, we set
  # TORCH_CUDA_ARCH_LIST to the latest architecture.
  CUDAARCHSARR=(${CUDAARCHS//;/ })
  LAST_ARCHITECTURE=${CUDAARCHSARR[-1]}
  # TORCH_CUDA_ARCH_LIST has to be at least 70 to override Volta default.
  if (( $LAST_ARCHITECTURE >= 70 )); then
    # Convert "75" to "7.5".
    TORCH_CUDA_ARCH_LIST=${LAST_ARCHITECTURE:0:-1}'.'${LAST_ARCHITECTURE: -1}
  fi
fi
    
export ROCM_PATH="${ROCM_PATH}"
declare -a CMAKE_FLAGS=(
  "-G${GENERATOR}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}" 
  "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}" 
  "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}" 
  "-DCMAKE_HIP_ARCHITECTURES=${CMAKE_HIP_ARCHITECTURES}" 
  "-DCUDA_TOOLKIT_ROOT_DIR=${CUDA_TOOLKIT_ROOT_DIR}" 
  "-DROCM_ROOT=${ROCM_PATH}" 
  "-DTORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}" 
  "-DUSE_ROCM=${USE_ROCM}"
  "-DGPU_TARGETS=${GPU_TARGETS:-}"
  "-DAMDGPU_TARGETS=${AMDGPU_TARGETS:-}"
  "-DCMAKE_HIP_ARCHITECTURES=${CMAKE_HIP_ARCHITECTURES:-}"
  "-DUSE_CUDA=${USE_CUDA}" 
)

export PATH="${PATH}:${ROCM_PATH}/lib/llvm/bin/"
echo "graphbolt cmake flags: ${CMAKE_FLAGS[@]}"

if [ $# -eq 0 ]; then
  "${CMAKE_COMMAND}" "${CMAKE_FLAGS[@]}" "${GRAPHBOLT_SRCDIR}"
  cmake --build .
  # CPSOURCE deliberately unquoted to expand wildcard
  cp -v $CPSOURCE "${GRAPHBOLT_BINDIR}"
else
  for PYTHON_INTERP in $@; do
    TORCH_VER="$("${PYTHON_INTERP}" -c 'import torch; print(torch.__version__.split("+")[0])')"
    mkdir -p "${TORCH_VER}"
    cd "${TORCH_VER}"
    "${CMAKE_COMMAND}" "${CMAKE_FLAGS[@]}" -DPYTHON_INTERP="${PYTHON_INTERP}" "${GRAPHBOLT_SRCDIR}" 
    cmake --build .
    # CPSOURCE deliberately unquoted to expand wildcard
    cp -v $CPSOURCE "${GRAPHBOLT_BINDIR}"
    cd ..
  done
fi
