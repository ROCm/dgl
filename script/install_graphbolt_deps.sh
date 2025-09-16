#!/usr/bin/env bash
export CC=/opt/rocm/llvm/bin/clang
export CXX=/opt/rocm/llvm/bin/clang++

# install 
    # Not installed by default
git clone https://github.com/ROCm/libhipcxx.git 
cd libhipcxx && git checkout v2.2.0 
mkdir build && cd build 
cmake -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=/opt/rocm .. 
cmake --build . --target install 
cd ../.. 

# Need to patch for https://github.com/ROCm/hipCollections/issues/7, https://github.com/ROCm/hipCollections/issues/8, https://github.com/ROCm/hipCollections/issues/9
git clone https://github.com/tpopp/hipCollections.git 
cd hipCollections && git checkout 6e31da8fd309f229d28adde8583a30bb4efaf1b7 
mkdir build && cd build 
cmake -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=/opt/rocm -DINSTALL_CUCO=ON -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF .. 
cmake --build . --target install 
cd ../.. 

# Need to patch for https://github.com/ROCm/rocm-libraries/issues/94. Fixed in https://github.com/ROCm/rocm-libraries/commit/2539bb2e1cd17d287f532a65125b662bf0b658dc
git clone https://github.com/tpopp/hipCUB.git
cd hipCUB
git checkout f342111197dd020f1c4210b16aa550b08992e97b
mkdir build
cd build
cmake -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=/opt/rocm ..
cmake --build . --target install
cd ../..

# Need to patch for https://github.com/ROCm/rocm-libraries/issues/101.
# Should be fixed in
# https://github.com/ROCm/rocm-libraries/commit/e403601a2abe4a305cafd6526af2dc9bc69823e2#diff-7579081ee4dda43a07274a2397b8277bfa022af6d485ba086efc66a124ee8f5b
git clone https://github.com/tpopp/rocThrust.git
cd rocThrust
git checkout 613db9a025709fb18f2a676543a17850bd231b04
mkdir build
cd build
cmake -DGPU_TARGETS="${GPU_TARGETS}" -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" -DCMAKE_HIP_ARCHITECTURES="${CMAKE_HIP_ARCHITECTURES}" \
        -DCMAKE_INSTALL_PREFIX=/opt/rocm ..
cmake --build . --target install
cd ../.. 