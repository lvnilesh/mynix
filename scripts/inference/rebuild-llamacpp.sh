#!/usr/bin/env bash
set -euo pipefail

cd ~/inference/llama.cpp
echo "Resetting local changes and pulling latest..."
git checkout .
git pull

# Locate the real NVIDIA driver libraries (not stubs)
NVIDIA_LIB="$(dirname "$(readlink -f /run/opengl-driver/lib/libcuda.so)")"
echo "Using NVIDIA libs from: $NVIDIA_LIB"

echo "Building with CUDA..."
NIXPKGS_ALLOW_UNFREE=1 nix-shell -p cudaPackages.cudatoolkit cmake gnumake gcc --impure --run "
  export LIBRARY_PATH=${NVIDIA_LIB}:\${LIBRARY_PATH:-}
  export LD_LIBRARY_PATH=${NVIDIA_LIB}:\${LD_LIBRARY_PATH:-}
  cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_COMPILER_LIBRARY_ROOT=${NVIDIA_LIB}/.. && \
  cmake --build build --config Release -j\$(nproc)
"

echo "Done. Restart the active model service:"
echo "  sudo systemctl restart qwen27"
echo "  sudo systemctl restart qwen35"
echo "  sudo systemctl restart gemma431"
echo "  sudo systemctl restart carnice27"
echo "  sudo systemctl restart qwen25vl7b"
