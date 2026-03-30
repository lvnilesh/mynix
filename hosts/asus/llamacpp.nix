# llama.cpp inference services for Qwen models (ASUS / RTX 4090).
#
# Models are stored in ~/inference/models/ and served via llama-server
# on port 8001. Only one model can run at a time (they Conflict).
#
# Launch scripts: scripts/inference/{qwen27,qwen35}
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
#   scripts/inference/rebuild-llamacpp.sh
{pkgs, ...}: let
  user = "cloudgenius";
  homeDir = "/home/${user}";
  inferenceDir = "${homeDir}/inference";
  scriptsDir = ../../scripts/inference;
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
      ExecStart = "${scriptsDir}/qwen35";
      MemoryMax = "28G";
      MemorySwapMax = "0";
      OOMPolicy = "stop";
      Restart = "on-failure";
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
      ExecStart = "${scriptsDir}/qwen27";
      MemoryMax = "24G";
      MemorySwapMax = "0";
      OOMPolicy = "stop";
      Restart = "on-failure";
      RestartSec = 30;
      StartLimitBurst = 5;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # nomic-embed moved to nuc (1080 Ti eGPU) — 2026-03-29

  # Open port for LAN access: 8001 (llama-server)
  networking.firewall.allowedTCPPorts = [8001];
}
