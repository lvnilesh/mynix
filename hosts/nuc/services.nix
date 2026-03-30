# NUC inference services
# nomic-embed on the 1080 Ti (only GPU), port 8002
# ollama as secondary inference server, port 11434
{
  pkgs,
  config,
  ...
}: let
  user = "cloudgenius";
  homeDir = "/home/${user}";
  inferenceDir = "${homeDir}/inference";
  cudaLibs = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cuda_cudart}/lib:${pkgs.linuxPackages.nvidia_x11}/lib";
in {
  # Nomic Embed Text v1.5 — embedding server
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

  # Ollama — for larger models when needed
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
  };

  # Don't auto-start ollama — start manually when needed
  systemd.services.ollama.wantedBy = pkgs.lib.mkForce [];

  # Open ports: 8002 (embedding), 8200 (whisper), 5100 (tts), 5200 (voice-bridge), 11434 (ollama)
  networking.firewall.allowedTCPPorts = [8002 8200 5100 5200 11434];
}
