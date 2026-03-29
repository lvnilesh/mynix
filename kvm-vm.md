# KVM Virtual Machines — One-Liner Scripts

Fully automated VM creation on KVM/libvirt (NixOS/ASUS). Both scripts create UEFI VMs with bridged networking, remote console access, and SSH — from a single command.

## Prerequisites

- NixOS host with libvirt/QEMU configured (see `hosts/common/virtualization.nix`)
- OVMF firmware at `/etc/ovmf/OVMF_CODE.ms.fd` and `/etc/ovmf/OVMF_VARS.ms.fd`
- User in `kvm` and `libvirt` groups
- `br0` bridge network defined in libvirt (bridged to LAN)
- Tools: `curl`, `python3`, `mcopy`, `mkfs.fat` (Windows), `openssl` (Ubuntu)

## Remote Management (both VMs)

From any machine on the LAN:

```bash
# virt-manager (Mac, Linux)
virt-manager -c "qemu+ssh://cloudgenius@asus/system"

# SSH
ssh cloudgenius@<vm-ip>
```

---

# Windows 11 — `w11-onliner`

## Quick Start

```bash
# Fully automated (one command)
./w11-onliner --fresh --password 's3cret' --post-install

# Custom hostname and username
./w11-onliner --fresh --hostname devbox --user admin --password 'Pass123' --post-install

# Enable SSH+RDP on an existing running VM (idempotent)
./w11-onliner --hostname win11 --post-install
```

### What happens

1. Auto-detects latest Win11 ISO from `~/Downloads` (or downloads from `download.i.cloudgenius.app/Windows/`)
2. Auto-fetches latest virtio-win drivers from Fedora
3. Generates `autounattend.xml` on a virtual floppy:
   - Selects Windows 11 Pro (generic KMS key for edition selection only)
   - Loads virtio drivers during WindowsPE (storage, network, display, balloon, serial)
   - Auto-partitions disk (EFI + MSR + Windows)
   - Bypasses Microsoft account (BypassNRO)
   - Creates local admin account, auto-logons once
   - Installs virtio-win guest tools + QEMU guest agent on first logon
4. Creates 200G virtio disk, UEFI + TPM 2.0 + Secure Boot VM
5. `--post-install` waits for guest agent, then configures:
   - OpenSSH Server (PowerShell as default shell)
   - Remote Desktop (enables services, firewall rules, reboots if needed)

### Manual steps

During Windows Setup, three prompts require manual input:

1. **"Press any key to boot from CD/DVD"** — baked into the Windows ISO bootloader, cannot be suppressed
2. **Region selection** — "Is this the right country or region?" — select United States
3. **Keyboard layout** — select US keyboard, skip second layout

After these three clicks, the rest of the install is fully unattended (disk partitioning, Pro edition selection, account creation, driver install, guest agent install).

## Flags

| Flag | Description |
|------|-------------|
| `--fresh` | Wipe disk + NVRAM, recreate from scratch (implies `--force`) |
| `--force` | Undefine existing domain, keep disk |
| `--hostname NAME` | VM name and Windows computer name (default: `win11`) |
| `--user NAME` | Local account username (default: `cloudgenius`) |
| `--password PASS` | Password. Prompts interactively if omitted |
| `--post-install` | Enable SSH + RDP via guest agent (idempotent, works on running VMs) |
| `--disk-bus virtio\|sata` | Disk bus (default: `virtio`, auto-fetches drivers) |
| `--drivers-iso PATH` | Explicit virtio-win ISO path |
| `--auto-drivers` | Force re-download latest virtio-win |
| `--arch x64\|arm64` | CPU architecture (default: auto-detect) |
| `--no-autounattend` | Skip unattended setup, manual OOBE |
| `-h` | Show help |

## VM Specs

| Resource | Value |
|----------|-------|
| RAM | 16 GiB |
| vCPUs | 8 (host-passthrough) |
| Disk | 200 GB qcow2, virtio |
| Graphics | VNC (QXL video) |
| Network | br0 bridge (LAN DHCP) |
| Firmware | UEFI + TPM 2.0 + Secure Boot |

## Examples

```bash
./w11-onliner --fresh --password 's3cret' --post-install          # Default: win11, cloudgenius
./w11-onliner --fresh --hostname another11 --password 's3cret'    # Custom hostname
./w11-onliner --fresh --disk-bus sata --post-install               # SATA (no virtio drivers)
./w11-onliner --fresh --no-autounattend                            # Manual Windows setup
./w11-onliner --hostname win11 --post-install                      # Post-install on running VM
./w11-onliner --force                                              # Redefine XML, keep disk
```

## Files

| Path | Purpose |
|------|---------|
| `/var/lib/libvirt/images/<hostname>.qcow2` | VM disk |
| `/var/lib/libvirt/qemu/nvram/<hostname>_VARS.fd` | UEFI NVRAM |
| `/var/lib/libvirt/boot/virtio-win-*.iso` | Cached virtio drivers |
| `~/Downloads/Win11_*_English_*.iso` | Windows ISO (auto-detected) |

## ISO Sources

- **Windows 11**: `~/Downloads` → `https://download.i.cloudgenius.app/Windows/` (supports v2 and arm64 variants)
- **Virtio-win**: `https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/`

## Notes

- The generic Pro key (`VK7JG-NPHTM-C97JM-9MPGT-3V66T`) is for edition selection only — does not activate Windows
- Guest tools + QEMU guest agent auto-install on first logon via `FirstLogonCommands`
- RDP may require a reboot on first enable — the script handles this automatically
- All operations are idempotent: safe to re-run on existing VMs

---

# Ubuntu LTS — `ubuntu-onliner`

## Quick Start

```bash
# Fully automated (one command)
./ubuntu-onliner --fresh --password 's3cret' --post-install

# Custom hostname and user
./ubuntu-onliner --fresh --hostname devbox --user admin --password 'Pass123' --post-install

# Verify SSH on running VM
./ubuntu-onliner --hostname ubuntu --post-install
```

### What happens

1. Auto-detects Ubuntu Server LTS ISO from `~/Downloads` (or downloads 24.04 LTS)
2. Generates cloud-init autoinstall seed ISO:
   - Sets hostname, username, password
   - Authorizes SSH key (auto-detects `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`)
   - Installs `ubuntu-desktop-minimal`, `openssh-server`, `qemu-guest-agent`
   - LVM storage, auto-partitioned
   - Enables SSH and guest agent services
3. Creates virtio disk, UEFI VM
4. `--post-install` waits for SSH to become available and reports connection info

### No manual steps

Ubuntu autoinstall is fully unattended — no keypresses required.

## Flags

| Flag | Description |
|------|-------------|
| `--fresh` | Wipe disk + NVRAM, recreate from scratch (implies `--force`) |
| `--force` | Undefine existing domain, keep disk |
| `--hostname NAME` | VM name and hostname (default: `ubuntu`) |
| `--user NAME` | Username (default: `cloudgenius`) |
| `--password PASS` | Password. Prompts interactively if omitted |
| `--ssh-key FILE` | SSH public key file (default: `~/.ssh/id_ed25519.pub`) |
| `--post-install` | Wait for SSH and verify access |
| `--ram MiB` | Memory in MiB (default: `4096`) |
| `--vcpus N` | vCPUs (default: `4`) |
| `--disk GB` | Disk size in GB (default: `60`) |
| `--iso PATH` | Ubuntu Server ISO path (auto-downloads if omitted) |
| `--no-autoinstall` | Skip autoinstall, manual setup |
| `-h` | Show help |

## VM Specs

| Resource | Value |
|----------|-------|
| RAM | 4 GiB |
| vCPUs | 4 (host-passthrough) |
| Disk | 60 GB qcow2, virtio |
| Graphics | VNC (QXL video) |
| Network | br0 bridge (LAN DHCP) |
| Firmware | UEFI |
| Desktop | Ubuntu Desktop Minimal |

## Examples

```bash
./ubuntu-onliner --fresh --password 's3cret' --post-install        # Default: ubuntu, cloudgenius
./ubuntu-onliner --fresh --hostname udev --password 's3cret'       # Custom hostname
./ubuntu-onliner --fresh --ram 8192 --vcpus 8 --disk 100           # Bigger VM
./ubuntu-onliner --fresh --no-autoinstall                           # Manual Ubuntu install
./ubuntu-onliner --hostname ubuntu --post-install                   # Check SSH on running VM
```

## Files

| Path | Purpose |
|------|---------|
| `/var/lib/libvirt/images/<hostname>.qcow2` | VM disk |
| `/var/lib/libvirt/qemu/nvram/<hostname>_VARS.fd` | UEFI NVRAM |
| `~/Downloads/ubuntu-*-live-server-amd64.iso` | Ubuntu ISO (auto-detected) |

## ISO Source

- **Ubuntu**: `~/Downloads` → `https://releases.ubuntu.com/24.04.2/` (auto-downloads latest 24.04 LTS)

