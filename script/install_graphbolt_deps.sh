#!/usr/bin/env bash

ROCM_ROOT=/opt/rocm

export CC=${ROCM_ROOT}/llvm/bin/clang
export CXX=${ROCM_ROOT}/llvm/bin/clang++

set -x
INSTALL_PREFIX=${ROCM_ROOT}
FILE_SOURCE_DIR=$(dirname $(realpath $0))
DEPS_DIR=$(pwd)
export CMAKE_PREFIX_PATH="/opt/rocm/hip/lib/cmake;/opt/rocm/lib/cmake"  

git clone https://github.com/ROCm/hipCollections.git -b release/rocmds-25.10
export RAPIDS_CMAKE_SCRIPT_BRANCH=release/rocmds-25.10
cd hipCollections
cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DINSTALL_CUCO=ON -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF
cmake --build build --target install
cd ${DEPS_DIR}

# TODO (#21) this is an unacceptable way to do this,
# see https://github.com/ROCm/libhipcxx/issues/10 for more details
# This was implicitly not allowed in previous releases we were using, 
# but with v2.7.0 they are explicitly not allowed.

# We only use semaphores for a counter of IO operations in graphbolt, 
# that only runs on the host (not on the device) so we should be "safe"
# to use this for now.
sed -i '/#error semaphore is not supported on AMD hardware and should not be included/d' ${INSTALL_PREFIX}/include/rapids/libhipcxx/cuda/semaphore
sed -i '/#error semaphore is not supported on AMD hardware and should not be included/d' ${INSTALL_PREFIX}/include/rapids/libhipcxx/hip/semaphore
sed -i '/#error semaphore is not supported on AMD hardware and should not be included/d' ${INSTALL_PREFIX}/include/rapids/libhipcxx/cuda/std/semaphore
sed -i '/#error semaphore is not supported on AMD hardware and should not be included/d' ${INSTALL_PREFIX}/include/rapids/libhipcxx/hip/std/semaphore

# TODO (#22) remove this once the patches are merged
# the patches for this were merged in https://github.com/ROCm/rocm-libraries/pull/1883
# but may take more time to be released.

# Right now we need to patch the rocPRIM headers to fix the build because these
# config headers are missing gfx942 (I've added them manually)
cp ${FILE_SOURCE_DIR}/*.hpp ${INSTALL_PREFIX}/include/rocprim/device/detail/config/.
