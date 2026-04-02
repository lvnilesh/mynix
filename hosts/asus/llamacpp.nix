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
    after = ["network.target" "nvidia-persistenced.service"];
    wants = ["network.target"];
    requires = ["nvidia-persistenced.service"];
    conflicts = ["qwen27.service" "ollama.service"];
    environment = {
      LD_LIBRARY_PATH = cudaLibs;
      CUDA_VISIBLE_DEVICES = "0"; # RTX 4090 only
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
      # Hardening — inference should not touch system state
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ReadWritePaths = [inferenceDir];
    };
  };

  systemd.services.qwen27 = {
    description = "Qwen3.5 27B Model Server (llama.cpp)";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "nvidia-persistenced.service"];
    wants = ["network.target"];
    requires = ["nvidia-persistenced.service"];
    conflicts = ["qwen35.service" "ollama.service"];
    environment = {
      LD_LIBRARY_PATH = cudaLibs;
      CUDA_VISIBLE_DEVICES = "0"; # RTX 4090 only
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
      # Hardening — inference should not touch system state
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ReadWritePaths = [inferenceDir];
    };
  };

  # nomic-embed moved to nuc (1080 Ti eGPU) — 2026-03-29

  # Open port for LAN access: 8001 (llama-server)
  # Restrict to LAN subnet — inference API should not be internet-accessible
  networking.firewall.extraCommands = ''
    iptables -I INPUT -p tcp --dport 8001 -s 127.0.0.0/8 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8001 -s 192.168.1.0/24 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8001 -j DROP
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D INPUT -p tcp --dport 8001 -s 127.0.0.0/8 -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 8001 -s 192.168.1.0/24 -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 8001 -j DROP 2>/dev/null || true
  '';
}
