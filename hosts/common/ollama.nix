# Ollama inference server on the 1080 Ti (GPU 1).
# Used as Clara's tertiary AI fallback (mistral-small3.2:24b).
# Port 11434 — OpenAI-compatible API.
#
# The 4090 (GPU 0) is reserved for llama.cpp (qwen27/qwen35).
# Ollama is restricted to GPU 1 via CUDA_VISIBLE_DEVICES.
#
# Usage:
#   sudo systemctl start ollama
#   ollama pull mistral-small3.2:24b
#   curl http://localhost:11434/v1/models
{pkgs, ...}: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "1";
    };
  };

  # Open port for LAN access
  networking.firewall.allowedTCPPorts = [11434];
}
