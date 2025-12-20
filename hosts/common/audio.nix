{pkgs, ...}: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Set Scarlett Solo as default audio device (both sink and source)
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-scarlett-solo-default.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              {
                node.name = "~alsa_output.usb-Focusrite_Scarlett_Solo.*"
              }
            ]
            actions = {
              update-props = {
                priority.driver = 3000
                priority.session = 3000
              }
            }
          }
          {
            matches = [
              {
                node.name = "~alsa_input.usb-Focusrite_Scarlett_Solo.*"
              }
            ]
            actions = {
              update-props = {
                priority.driver = 3000
                priority.session = 3000
              }
            }
          }
        ]
      '')
    ];
  };
}
