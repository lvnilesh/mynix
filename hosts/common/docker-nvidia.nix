{
  pkgs,
  config,
  ...
}: {
  # Ensure nvidia-docker compatibility
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    runc
    libnvidia-container
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features = {
        cdi = true;
      };
      runtimes = {
        nvidia = {
          path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
        };
      };
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  # CDI mode:  docker run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi
  # Runtime mode: docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
}
