#"Copyright Advanced Micro Devices, Inc.
#Licensed under the Apache License Version 2.0"

#!/bin/bash
# Helper script to build graphbolt libraries for PyTorch
set -euo pipefail
GRAPHBOLT_SRCDIR=$(dirname $0)
GRAPHBOLT_BINDIR=$BINDIR/graphbolt
GRAPHBOLT_BUILD_DIR=$GRAPHBOLT_BINDIR

mkdir -p $GRAPHBOLT_BUILD_DIR
cd $GRAPHBOLT_BUILD_DIR

if [ $(uname) = 'Darwin' ]; then
  CPSOURCE=*.dylib
else
  CPSOURCE=*.so
fi

CMAKE_FLAGS="-DCMAKE_CXX_FLAGS='-fuse-ld=mold' -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DROCMARCHS=${ROCMARCHS} -DUSE_HIP=$USE_HIP -DGPU_TARGETS=${ROCMARCHS}"
echo "graphbolt cmake flags: $CMAKE_FLAGS"

if [ $# -eq 0 ]; then
  $CMAKE_COMMAND $CMAKE_FLAGS -S $GRAPHBOLT_SRCDIR -B $GRAPHBOLT_BUILD_DIR
  cmake --build $GRAPHBOLT_BUILD_DIR --parallel
  # cp -v $CPSOURCE $GRAPHBOLT_BINDIR
else
  for PYTHON_INTERP in $@; do
    TORCH_VER=$($PYTHON_INTERP -c 'import torch; print(torch.__version__.split("+")[0])')
    mkdir -p $TORCH_VER
    cd $TORCH_VER
    $CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP -S $GRAPHBOLT_SRCDIR -B $GRAPHBOLT_BUILD_DIR
    cmake --build $GRAPHBOLT_BUILD_DIR --parallel
    # cp -v $CPSOURCE $GRAPHBOLT_BINDIR
    cd ..
  done
fi
