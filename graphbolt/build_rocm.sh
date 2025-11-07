#"Copyright Advanced Micro Devices, Inc.
#Licensed under the Apache License Version 2.0"

#!/bin/bash
# Helper script to build graphbolt libraries for PyTorch
set -euo pipefail
GRAPHBOLT_SRCDIR=$(dirname $0)
# We build directly in our primary build directory
GRAPHBOLT_BINDIR=$BINDIR/graphbolt
GRAPHBOLT_BUILD_DIR=$GRAPHBOLT_BINDIR

mkdir -p $GRAPHBOLT_BUILD_DIR
cd $GRAPHBOLT_BUILD_DIR

if [ $(uname) = 'Darwin' ]; then
  CPSOURCE=*.dylib
else
  CPSOURCE=*.so
fi

CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_HIP_ARCHITECTURES=${CMAKE_HIP_ARCHITECTURES} -DUSE_HIP=$USE_HIP -DGPU_TARGETS=${CMAKE_HIP_ARCHITECTURES}"
echo "graphbolt cmake flags: $CMAKE_FLAGS"

if [ $# -eq 0 ]; then
  $CMAKE_COMMAND $CMAKE_FLAGS -S $GRAPHBOLT_SRCDIR -B $GRAPHBOLT_BUILD_DIR
  cmake --build $GRAPHBOLT_BUILD_DIR --parallel --verbose
else
  for PYTHON_INTERP in $@; do
    TORCH_VER=$($PYTHON_INTERP -c 'import torch; print(torch.__version__.split("+")[0])')
    mkdir -p $TORCH_VER
    cd $TORCH_VER
    $CMAKE_COMMAND $CMAKE_FLAGS -DPYTHON_INTERP=$PYTHON_INTERP -S $GRAPHBOLT_SRCDIR -B $GRAPHBOLT_BUILD_DIR
    cmake --build $GRAPHBOLT_BUILD_DIR --parallel --verbose
    cd ..
  done
fi
