{
  pkgs,
  config,
  ...
}: {
  # Ensure nvidia-docker compatibility
  environment.systemPackages = with pkgs; [
    runc
    # libnvidia-container
    # nvidia-container-toolkit
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features = {
        cdi = true;
      };
    };
  };

  #  hardware.nvidia-container-toolkit.enable = true;

  # docker run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi
  # docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
}
