## Build docker image for CI

### CPU image
```bash
docker build -t dgl-cpu -f Dockerfile.ci_cpu .
```

### Nvidia image
```bash
docker build -t dgl-gpu -f Dockerfile.ci_gpu .
```

### Rocm images

These images can be fetched from Docker Hub as gcmn/dgl:rocm-deps-only and
gcmn/dgl:rocm-complete.

#### Dependencies for building and running DGL

This image does not need any context, so you can build it passing the Dockerfile
from stdin.

```bash
docker build -t dgl-rocm-deps-only - < Dockerfile.rocm-deps-only
```

To limit the build to only specific GPU architectures, pass in the `GPU_TARGETS`
build argument

```bash
docker build -t dgl-rocm-deps-only-gfx90a --build-arg GPU_TARGETS=gfx90a - \
    < Dockerfile.rocm-deps-only
```

#### Image with DGL itself

In contrast, this needs the entire DGL repository as context. If you have
hipified sources checked out (e.g. you are on the `hipify-inplace` branch) then
the context can just be the working directory (ensure any large non-source
directories are in the `.dockerignore` file)

```bash
cd "${DGL_HOME}"
docker build -t dgl-rocm-complete -f docker/Dockerfile.rocm-complete .
```

Otherwise (e.g. if you're iterating on the Dockerfile while based on the
`hip-ready` branch) you'll need to create a separate git worktree, either by
cloning the repository in another directory or by using `git worktree`. Don't
forget to clone submodules! (if it weren't for submodules you could easily use
`git archive`). For example

```bash
git worktree add -d /tmp/dgl-for-docker hipify-inplace
pushd /tmp/dgl-for-docker
git submodule update --init -j 8
popd
docker build -t dgl-rocm-complete -f docker/Dockerfile.rocm-complete /tmp/dgl-for-docker
```

To override the base image with your own locally built one

```bash
docker build -t dgl-rocm-complete -f docker/Dockerfile.rocm-complete \
    --build-context gcmn/dgl:rocm-deps-only=docker-image://dgl-rocm-deps-only \
    .
```

To limit the build to only specific GPU architectures, pass in the `GPU_TARGETS`

```bash
docker build -t dgl-rocm-complete-gfx90a -f docker/Dockerfile.rocm-complete \
    --build-arg GPU_TARGETS=gfx90a \
    .
```

or override the base image to one with only those `GPU_TARGETS`

```bash
docker build -t dgl-rocm-complete -f docker/Dockerfile.rocm-complete \
    --build-context gcmn/dgl:rocm-deps-only=docker-image://dgl-rocm-deps-only-gfx90a \
    .
```

### Lint image
```bash
docker build -t dgl-lint -f Dockerfile.ci_lint .
```

### CPU image for kg
```bash
wget https://data.dgl.ai/dataset/FB15k.zip -P install/
docker build -t dgl-cpu:torch-1.2.0 -f Dockerfile.ci_cpu_torch_1.2.0 .
```

### GPU image for kg
```bash
wget https://data.dgl.ai/dataset/FB15k.zip -P install/
docker build -t dgl-gpu:torch-1.2.0 -f Dockerfile.ci_gpu_torch_1.2.0 .
```
