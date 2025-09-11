#"Copyright Advanced Micro Devices, Inc.
#Licensed under the Apache License Version 2.0"

#!/bin/bash
# Helper script to build graphbolt libraries for PyTorch
set -e

mkdir -p build
mkdir -p $BINDIR/graphbolt
cd build

if [ $(uname) = 'Darwin' ]; then
  CPSOURCE=*.dylib
else
  CPSOURCE=*.so
fi

CMAKE_FLAGS="-DROCMARCHS=${ROCMARCHS} -DUSE_HIP=$USE_HIP -DGPU_TARGETS=${ROCMARCHS}"
echo "graphbolt cmake flags: $CMAKE_FLAGS"

if [ $# -eq 0 ]; then
  $CMAKE_COMMAND $CMAKE_FLAGS ..
  cmake --build . --parallel
  cp -v $CPSOURCE $BINDIR/graphbolt
else
  for PYTHON_INTERP in $@; do
    TORCH_VER=$($PYTHON_INTERP -c 'import torch; print(torch.__version__.split("+")[0])')
    mkdir -p $TORCH_VER
    cd $TORCH_VER
    $CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP ../..
    cmake --build . --parallel
    cp -v $CPSOURCE $BINDIR/graphbolt
    cd ..
  done
fi
