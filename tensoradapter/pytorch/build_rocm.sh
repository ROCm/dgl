#Copyright Advanced Micro Devices, Inc.
#Licensed under the Apache License Version 2.0

#!/bin/bash
# Helper script to build tensor adapter libraries for PyTorch
set -e

mkdir -p build
mkdir -p $BINDIR/tensoradapter/pytorch
cd build

if [ $(uname) = 'Darwin' ]; then
        CPSOURCE=*.dylib
else
        CPSOURCE=*.so
fi

CMAKE_FLAGS="-DPYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH} -DUSE_HIP=${USE_HIP}"

if [ $# -eq 0 ]; then
        echo "$CMAKE_COMMAND $CMAKE_FLAGS"
        $CMAKE_COMMAND $CMAKE_FLAGS ..
        cmake --build .
        cp -v $CPSOURCE $BINDIR/tensoradapter/pytorch
else
        for PYTHON_INTERP in $@; do
                TORCH_VER=$($PYTHON_INTERP -c 'import torch; print(torch.__version__.split("+")[0])')
                mkdir -p $TORCH_VER
                cd $TORCH_VER
        echo "torch=$TORCH_VER $CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP ../.."
                $CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP ../..
                cmake --build .
                cp -v $CPSOURCE $BINDIR/tensoradapter/pytorch
                cd ..
        done
fi

