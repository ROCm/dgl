# "Copyright Advanced Micro Devices, Inc.
# Licensed under the Apache License Version 2.0"
"""
This is the global script that set the version information of DGL.
This script runs and update all the locations that related to versions
List of affected files:
- dgl-root/python/dgl/_ffi/libinfo.py
- dgl-root/include/dgl/runtime/c_runtime_api.h
- dgl-root/conda/dgl/meta.yaml
"""

import os
import re

# current version of upstream is tracked by the ROCM version
# The environment variable DGL_PRERELEASE is the prerelase suffix
# (usually "aYYMMDD")
# The environment variable DGL_VERSION_SUFFIX is the local version label
# suffix for indicating CPU and CUDA versions as in PEP 440 (e.g. "+cu102")
__version__ = os.getenv("DGL_RELEASE_VERSION", "2.4.0+amd0") + os.getenv(
    "DGL_PRERELEASE", ""
)
# we can only have a since + separating our public and local version labels
# see https://peps.python.org/pep-0440/#local-version-identifiers
# replace the + with _ in the VERSION_SUFFIX passed from the ENV
version_suffix = os.getenv("DGL_VERSION_SUFFIX", "").replace("+", "_")
if "+" in __version__:
    version_suffix = version_suffix.replace("+", "_")
__version__ += version_suffix
print(__version__)

# Implementations


def update(file_name, pattern, repl):
    update = []
    hit_counter = 0
    need_update = False
    for l in open(file_name):
        result = re.findall(pattern, l)
        if result:
            assert len(result) == 1
            hit_counter += 1
            if result[0] != repl:
                l = re.sub(pattern, repl, l)
                need_update = True
                print("%s: %s->%s" % (file_name, result[0], repl))
            else:
                print("%s: version is already %s" % (file_name, repl))

        update.append(l)
    if hit_counter != 1:
        raise RuntimeError("Cannot find version in %s" % file_name)

    if need_update:
        with open(file_name, "w") as output_file:
            for l in update:
                output_file.write(l)


def main():
    curr_dir = os.path.dirname(os.path.abspath(os.path.expanduser(__file__)))
    proj_root = os.path.abspath(os.path.join(curr_dir, ".."))
    # python path
    update(
        os.path.join(proj_root, "python", "dgl", "_ffi", "libinfo.py"),
        r"(?<=__version__ = \")[.0-9a-z+_]+",
        __version__,
    )
    # C++ header
    update(
        os.path.join(proj_root, "include", "dgl", "runtime", "c_runtime_api.h"),
        '(?<=DGL_VERSION ")[.0-9a-z+_]+',
        __version__,
    )
    # conda
    for path in ["dgl"]:
        update(
            os.path.join(proj_root, "conda", path, "meta.yaml"),
            "(?<=version: )[.0-9a-z+_]+",
            __version__,
        )


if __name__ == "__main__":
    main()
