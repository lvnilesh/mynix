#!/usr/bin/env bash
set -euo pipefail

cd ~/inference/llama.cpp
echo "Pulling latest..."
git pull

echo "Building with CUDA..."
NIXPKGS_ALLOW_UNFREE=1 nix-shell -p cudaPackages.cudatoolkit --impure --run \
  'cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release -j$(nproc)'

echo "Done. Restart the service if running:"
echo "  sudo systemctl restart qwen35"
echo "  sudo systemctl restart qwen27"
