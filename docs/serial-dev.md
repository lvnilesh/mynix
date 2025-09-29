# Serial Development Support

This repository now includes a minimal, always‑on serial development setup without feature flags:

## What Was Added
- Group membership (`dialout`, `uucp`) for user `cloudgenius` directly in each host file (`asus.nix`, `venus.nix`) so the user can access `/dev/ttyUSB*` & `/dev/ttyACM*` devices.
- A shared module `hosts/serial-perms.nix` that only contributes PlatformIO udev rules (no user logic) to ensure proper permissions and symlinks for common dev boards.
- `platformio-core` added to `environment.systemPackages` (in `hosts/common/apps.nix`) so the `pio` CLI is immediately available.

## Rationale
Keeping group membership in the host layer makes it explicit which machines grant hardware access, while the module stays reusable and side‑effect light. No boolean option was introduced—feature is simply present.

## Verifying Access
After a rebuild & relogin:
```bash
id | grep -E 'dialout|uucp'
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
```
You should see those devices readable/writable by one of the added groups.

## Using PlatformIO
```bash
pio --version
pio boards | head
```
Typical workflow:
```bash
mkdir -p ~/dev/blinky && cd ~/dev/blinky
pio project init --board uno
code .   # or your editor
pio run
pio run -t upload
```

## Troubleshooting
| Issue | Fix |
|-------|-----|
| Device shows `Permission denied` | Re-login (new groups), or ensure udev rule applied: `sudo udevadm control --reload && sudo udevadm trigger` |
| Multiple boards, port ambiguous | Use `pio device list` to pick correct `/dev/tty*` |
| Board not recognized | Update PlatformIO packages: `pio update` |

## Extending
If you need custom udev tweaks, append another module that adds to `services.udev.extraRules` instead of modifying `serial-perms.nix`.

---
Generated automatically; feel free to edit for project specifics.
