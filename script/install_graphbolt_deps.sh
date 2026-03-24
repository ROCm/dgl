#!/usr/bin/env bash

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install graphbolt dependencies (hipCollections, rocPRIM patches).

Options:
  --rocm-root DIR           ROCm installation root. Takes priority over \$ROCM_ROOT and \$ROCM_PATH
                            env variables. Falls back to \$ROCM_ROOT, then \$ROCM_PATH, then /opt/rocm.
  --install-prefix DIR      Installation prefix for dependencies (default: same as rocm-root)
  --hipcollections-branch B Branch to clone hipCollections from (default: release/rocmds-25.10)
  --dry-run                 Print the commands that would be executed without running them
  -h, --help                Show this help message
EOF
  exit 0
}

_ROCM_ENV_SET=false
if [[ -n "${ROCM_ROOT}" || -n "${ROCM_PATH}" ]]; then
  _ROCM_ENV_SET=true
fi

ROCM_ROOT="${ROCM_ROOT:-${ROCM_PATH:-/opt/rocm}}"
INSTALL_PREFIX=""
HIPCOLLECTIONS_BRANCH="release/rocmds-25.10"
DRY_RUN=false
_ROCM_FLAG_SET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rocm-root)         ROCM_ROOT="$2"; _ROCM_FLAG_SET=true; shift 2 ;;
    --install-prefix)    INSTALL_PREFIX="$2"; shift 2 ;;
    --hipcollections-branch) HIPCOLLECTIONS_BRANCH="$2"; shift 2 ;;
    --dry-run)           DRY_RUN=true; shift ;;
    -h|--help)           usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

INSTALL_PREFIX="${INSTALL_PREFIX:-${ROCM_ROOT}}"

if ! $_ROCM_ENV_SET && ! $_ROCM_FLAG_SET; then
  echo "Neither ROCM_ROOT nor ROCM_PATH is set, defaulting to /opt/rocm."
fi
echo "ROCM_ROOT:      ${ROCM_ROOT}"
echo "INSTALL_PREFIX:  ${INSTALL_PREFIX}"

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

export CC=${ROCM_ROOT}/llvm/bin/clang
export CXX=${ROCM_ROOT}/llvm/bin/clang++

set -x
FILE_SOURCE_DIR=$(dirname $(realpath $0))
DEPS_DIR=$(pwd)
export CMAKE_PREFIX_PATH="${ROCM_ROOT}/hip/lib/cmake;${ROCM_ROOT}/lib/cmake"

run git clone https://github.com/ROCm/hipCollections.git -b "${HIPCOLLECTIONS_BRANCH}"
export RAPIDS_CMAKE_SCRIPT_BRANCH="${HIPCOLLECTIONS_BRANCH}"
run cd hipCollections
run cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DINSTALL_CUCO=ON -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF
run cmake --build build --target install
cd ${DEPS_DIR}

# TODO (#21) this is an unacceptable way to do this,
# see https://github.com/ROCm/libhipcxx/issues/10 for more details
# This was implicitly not allowed in previous releases we were using, 
# but with v2.7.0 they are explicitly not allowed.

# TODO (#22) remove this once the patches are merged
# the patches for this were merged in https://github.com/ROCm/rocm-libraries/pull/1883
# but may take more time to be released.

# Right now we need to patch the rocPRIM headers to fix the build because these
# config headers are missing gfx942 (I've added them manually)
run cp ${FILE_SOURCE_DIR}/*.hpp ${INSTALL_PREFIX}/include/rocprim/device/detail/config/.
