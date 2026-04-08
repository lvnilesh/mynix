#!/usr/bin/env bash
set -euo pipefail

cd ~/inference/llama.cpp
echo "Resetting local changes and pulling latest..."
git checkout .
git pull

echo "Building with CUDA..."
NIXPKGS_ALLOW_UNFREE=1 nix-shell -p cudaPackages.cudatoolkit cmake gnumake gcc --impure --run   'cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release -j$(nproc)'

echo "Done. Restart the active model service:"
echo "  sudo systemctl restart qwen27"
echo "  sudo systemctl restart qwen35"
echo "  sudo systemctl restart gemma431"
echo "  sudo systemctl restart carnice27"
echo "  sudo systemctl restart qwen25vl7b"
