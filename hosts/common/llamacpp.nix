# llama.cpp inference services for Qwen models.
#
# Models are stored in ~/inference/models/ and served via llama-server
# on port 8001. Only one model can run at a time (they Conflict).
#
# Usage:
#   sudo systemctl start qwen35    # start Qwen 35B
#   sudo systemctl start qwen27    # start Qwen 27B (stops 35B)
#   sudo systemctl stop qwen35     # stop
#   journalctl -u qwen35 -f        # logs
#
# Boot default: qwen27 has wantedBy = ["multi-user.target"] so it starts on boot.
# qwen35 does NOT start on boot. To change the boot default, move the wantedBy
# line from qwen27 to qwen35 and rebuild. Only one can have wantedBy since they
# conflict (shared port 8001).
#
# llama.cpp must be built first:
#   cd ~/inference/llama.cpp
#   nix-shell -p cudaPackages.cudatoolkit --impure \
#     --run 'cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release && cmake --build build -j$(nproc)'
{pkgs, ...}: let
  user = "cloudgenius";
  homeDir = "/home/${user}";
  inferenceDir = "${homeDir}/inference";
  # CUDA runtime libraries needed by llama-server (built with nix-shell CUDA)
  cudaLibs = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cuda_cudart}/lib:${pkgs.linuxPackages.nvidia_x11}/lib";
in {
  systemd.services.qwen35 = {
    description = "Qwen3.5 35B Model Server (llama.cpp)";
    after = ["network.target"];
    wants = ["network.target"];
    conflicts = ["qwen27.service" "ollama.service"];
    environment = {
      LD_LIBRARY_PATH = cudaLibs;
    };
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";
      WorkingDirectory = inferenceDir;
      ExecStart = "${inferenceDir}/scripts/qwen35";
      MemoryMax = "28G";
      MemorySwapMax = "0";
      Restart = "always";
      RestartSec = 30;
      StartLimitBurst = 5;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  systemd.services.qwen27 = {
    description = "Qwen3.5 27B Model Server (llama.cpp)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    wants = ["network.target"];
    conflicts = ["qwen35.service" "ollama.service"];
    environment = {
      LD_LIBRARY_PATH = cudaLibs;
    };
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";
      WorkingDirectory = inferenceDir;
      ExecStart = "${inferenceDir}/scripts/qwen27";
      MemoryMax = "24G";
      MemorySwapMax = "0";
      Restart = "always";
      RestartSec = 30;
      StartLimitBurst = 5;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Nomic Embed Text v1.5 on 1080 Ti (GPU 1) — embedding server
  systemd.services.nomic-embed = {
    description = "Nomic Embed Text v1.5 (llama.cpp on 1080 Ti)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    wants = ["network.target"];
    environment = {
      LD_LIBRARY_PATH = cudaLibs;
    };
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";
      WorkingDirectory = inferenceDir;
      ExecStart = "${inferenceDir}/scripts/nomic-embed";
      MemoryMax = "4G";
      MemorySwapMax = "0";
      Restart = "always";
      RestartSec = 10;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Open ports for LAN access: 8001 (llama-server), 8002 (embedding)
  networking.firewall.allowedTCPPorts = [8001 8002];
}
