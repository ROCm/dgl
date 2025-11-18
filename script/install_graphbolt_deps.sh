#!/usr/bin/env bash
export CC=${ROCM_CC_PATH:-/opt/rocm/llvm/bin/clang}
export CXX=${ROCM_CXX_PATH:-/opt/rocm/llvm/bin/clang++}
export HIP_PLATFORM=${ROCM_HIP_PLATFORM:-amd}

echo "DEBUG: CC: ${CC}"
echo "DEBUG: CXX: ${CXX}"
echo "DEBUG: HIP_PLATFORM: ${HIP_PLATFORM}"
echo "DEBUG: ROCM_HOME: ${ROCM_HOME}"
echo "DEBUG: ROCM_CC_PATH: ${ROCM_CC_PATH}"
echo "DEBUG: ROCM_CXX_PATH: ${ROCM_CXX_PATH}"
echo "DEBUG: ROCM_GPU_TARGETS: ${ROCM_GPU_TARGETS}"
echo "DEBUG: ROCM_VERSION: ${ROCM_VERSION}"
echo "DEBUG: PATH: ${PATH}"

# set the install prefix to the cwd/install
# INSTALL_PREFIX=$(pwd)/install
INSTALL_PREFIX=${ROCM_HOME:-/opt/rocm}
FILE_SOURCE_DIR=$(dirname $(realpath $0))
DEPS_DIR=$(pwd)

# Not installed by default
git clone https://github.com/ROCm/libhipcxx.git 
cd libhipcxx 
git checkout v2.2.0 
cmake -B build \
        -DGPU_TARGETS=${ROCM_GPU_TARGETS} \
        -DCMAKE_HIP_PLATFORM=${HIP_PLATFORM} \
        -DCMAKE_HIP_COMPILER=${ROCM_CXX_PATH} \
        -DCMAKE_HIP_COMPILER_ROCM_ROOT=${ROCM_HOME} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
        -DLIBCUDACXX_ENABLE_LIBCUDACXX_TESTS=OFF
cmake --build build --target install 
cd ${DEPS_DIR}

# Need to patch for https://github.com/ROCm/rocm-libraries/issues/101.
# Should be fixed in
# https://github.com/ROCm/rocm-libraries/commit/e403601a2abe4a305cafd6526af2dc9bc69823e2#diff-7579081ee4dda43a07274a2397b8277bfa022af6d485ba086efc66a124ee8f5b
git clone https://github.com/tpopp/rocThrust.git
cd rocThrust
git checkout 613db9a025709fb18f2a676543a17850bd231b04
cmake -B build \
        -DGPU_TARGETS=${ROCM_GPU_TARGETS} \
        -DCMAKE_HIP_PLATFORM=${HIP_PLATFORM} \
        -DCMAKE_HIP_COMPILER=${ROCM_CXX_PATH} \
        -DCMAKE_HIP_COMPILER_ROCM_ROOT=${ROCM_HOME} \
        -DCMAKE_HIP_ARCHITECTURES=${ROCM_GPU_TARGETS} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
cmake --build build --target install
cd ${DEPS_DIR}

# Need to patch for https://github.com/ROCm/hipCollections/issues/7, https://github.com/ROCm/hipCollections/issues/8, https://github.com/ROCm/hipCollections/issues/9
git clone https://github.com/tpopp/hipCollections.git 
cd hipCollections
git checkout 6e31da8fd309f229d28adde8583a30bb4efaf1b7 
cmake -B build \
        -DGPU_TARGETS=${ROCM_GPU_TARGETS} \
        -DCMAKE_HIP_PLATFORM=${HIP_PLATFORM} \
        -DCMAKE_HIP_COMPILER=${ROCM_CXX_PATH} \
        -DCMAKE_HIP_COMPILER_ROCM_ROOT=${ROCM_HOME} \
        -DCMAKE_HIP_ARCHITECTURES=${ROCM_GPU_TARGETS} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DINSTALL_CUCO=ON -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF
cmake --build build --target install
cd ${DEPS_DIR}


# if ROCM < 7.0 we also need to install rocThrust
ROCM_VERSION=$(${INSTALL_PREFIX}/bin/hipconfig --version)
#strip the major version from the ROCM_VERSION (before the dot)
ROCM_VERSION=${ROCM_VERSION%%.*}
echo "Working with ROCm Major Version: $ROCM_VERSION"
if [ "$ROCM_VERSION" -lt "7" ]; then

        # Need to patch for https://github.com/ROCm/rocm-libraries/issues/94. Fixed in https://github.com/ROCm/rocm-libraries/commit/2539bb2e1cd17d287f532a65125b662bf0b658dc
        git clone https://github.com/tpopp/hipCUB.git
        cd hipCUB
        git checkout f342111197dd020f1c4210b16aa550b08992e97b
        cmake -B build \
                -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
        cmake --build build --target install
        cd ${DEPS_DIR}
else
    echo "ROCm Major Version is 7.0 or higher, skipping hipCUB installation"
    # TODO remove this once the patches are merged
    # Right now we need to patch the rocPRIM headers to fix the build because these
    # config headers are missing gfx942 (I've added them manually)
    cp ${FILE_SOURCE_DIR}/*.hpp ${INSTALL_PREFIX}/include/rocprim/device/detail/config/.

fi



