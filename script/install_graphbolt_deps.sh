#!/usr/bin/env bash
export CC=/opt/rocm/llvm/bin/clang
export CXX=/opt/rocm/llvm/bin/clang++
export GPU_TARGETS="gfx942"
export AMDGPU_TARGETS="gfx942"
export CMAKE_HIP_ARCHITECTURES="gfx942"

# set the install prefix to the cwd/install
# INSTALL_PREFIX=$(pwd)/install
INSTALL_PREFIX=/opt/rocm
FILE_SOURCE_DIR=$(dirname $(realpath $0))

# install 
# Not installed by default
git clone https://github.com/ROCm/libhipcxx.git 
cd libhipcxx && git checkout v2.2.0 
cmake -B build -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} 
cmake --build build --target install 
cd ../

# Need to patch for https://github.com/ROCm/rocm-libraries/issues/101.
# Should be fixed in
# https://github.com/ROCm/rocm-libraries/commit/e403601a2abe4a305cafd6526af2dc9bc69823e2#diff-7579081ee4dda43a07274a2397b8277bfa022af6d485ba086efc66a124ee8f5b
git clone https://github.com/tpopp/rocThrust.git
cd rocThrust
git checkout 613db9a025709fb18f2a676543a17850bd231b04
cmake -B build -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} 
cmake --build build --target install
cd ../

# Need to patch for https://github.com/ROCm/hipCollections/issues/7, https://github.com/ROCm/hipCollections/issues/8, https://github.com/ROCm/hipCollections/issues/9
git clone https://github.com/tpopp/hipCollections.git 
cd hipCollections && git checkout 6e31da8fd309f229d28adde8583a30bb4efaf1b7 
cmake -B build -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DINSTALL_CUCO=ON -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF 
cmake --build build --target install --verbose
cd ../

# TODO remove this once the patches are merged
# Right now we need to patch the rocPRIM headers to fix the build because these
# config headers are missing gfx942 (I've added them manually)
cp ${FILE_SOURCE_DIR}/*.hpp ${INSTALL_PREFIX}/include/rocprim/device/detail/config/.