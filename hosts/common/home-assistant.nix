# Home Assistant — NixOS-managed smart home hub.
#
# State lives in /var/lib/hass/ (default NixOS path).
# After first boot, create a Long-Lived Access Token at:
#   http://localhost:8123/profile/security
# Then add HASS_TOKEN and HASS_URL to the hermes-agent-env
# Vaultwarden note so Hermes can control HA.
#
# Usage:
#   systemctl status home-assistant
#   journalctl -u home-assistant -f
#   http://localhost:8123        (web UI)
{pkgs, ...}: {
  services.home-assistant = {
    enable = true;

    extraComponents = [
      # Core
      "default_config"
      "met" # weather
      "radio_browser" # internet radio

      # Network discovery
      "ssdp"
      "zeroconf"

      # Common integrations — add more as needed
      "esphome"
      "mqtt"
      "tailscale"
      "xiaomi_aqara"
    ];

    # Declarative base config — HA merges this with UI-configured settings.
    # Integrations added through the web UI persist in /var/lib/hass/.storage/
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "us_customary";
        time_zone = "America/Los_Angeles";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
      };
      http = {
        server_port = 8123;
      };
      # Enable default integrations
      default_config = {};
    };
  };

  # Mosquitto MQTT broker — used by HA, ESPHome, Zigbee2MQTT, etc.
  # Credentials: MQTT_USER / MQTT_PASSWORD in Vaultwarden hermes-agent-env note.
  # Password hash file created by: ~/.hermes/mcp-servers/reset-ha-mqtt.sh
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        settings.allow_anonymous = false;
        users.homeassistant = {
          acl = ["readwrite #"];
          hashedPasswordFile = "/etc/mosquitto/passwd-homeassistant";
        };
      }
    ];
  };

  # Open firewall for HA web UI and MQTT on local network
  networking.firewall.allowedTCPPorts = [8123 1883];
}
