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

  # Put nvidia-persistenced on the CDI generator's PATH so it can discover
  # the binary (fixes "Could not locate nvidia-persistenced" warning at boot).
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    after = ["nvidia-persistenced.service"];
    path = [config.hardware.nvidia.package.persistenced];
  };

  # CDI mode:  docker run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi
  # Runtime mode: docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
}
