# NixOS Secure Boot Setup Guide

Complete guide to enable UEFI Secure Boot on NixOS using Lanzaboote and sbctl.

---

## What is This?

**Lanzaboote** is a Secure Boot-compatible bootloader for NixOS that replaces systemd-boot and automatically signs kernels and initrd files on every system rebuild.

**sbctl** is a user-friendly Secure Boot key manager that simplifies the process of creating and enrolling keys.

---

## Prerequisites

- NixOS system with UEFI firmware
- Lanzaboote module integrated in `flake.nix`
- Root/sudo access

---

## Complete Setup Process

### Step 1: Clear Existing UEFI Keys (CRITICAL for ASUS boards)

**In UEFI/BIOS:**
1. Reboot and press **Delete** or **F2** to enter UEFI
2. Press **F7** for Advanced Mode
3. Navigate to: **Boot** → **Secure Boot**
4. Find and select: **"Clear All Secure Boot Keys"** or **"Delete All Keys"**
5. Confirm the deletion
6. **Save and Exit** (F10)

**Why:** This puts the system in "Setup Mode" which allows enrolling custom keys. Without clearing, key enrollment may fail.

---

### Step 2: Boot into NixOS and Enroll Microsoft Keys

```bash
# Enroll Microsoft keys (required for dual-boot and proper Secure Boot operation)
sudo sbctl enroll-keys --microsoft

# Verify enrollment
sudo sbctl status
```

**Expected output:**
```
Installed:    ✓ sbctl is installed
Setup Mode:   ✓ Disabled  (keys are now enrolled)
Secure Boot:  ✗ Disabled  (not yet enabled in UEFI)
Vendor Keys:  microsoft
```

**Important:** The `--microsoft` flag includes Microsoft's keys, which enables:
- Dual-boot with Windows
- Compatibility with ASUS UEFI "Windows UEFI mode"
- Broader hardware driver support

---

### Step 3: Enable Lanzaboote in NixOS Configuration

Edit `hosts/common/bootloader.nix`:

```nix
# Disable systemd-boot (mutually exclusive with lanzaboote)
boot.loader.systemd-boot.enable = lib.mkForce false;

# Enable lanzaboote
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/etc/secureboot";
};
```

---

### Step 4: Rebuild System

```bash
cd ~/mynix
./redo
```

**What happens:**
- Lanzaboote installs to `/boot`
- All boot files (kernels, initrds) are automatically signed
- systemd-boot is removed

**Verify signatures:**
```bash
sudo sbctl verify | head -20
```

You should see: `✓ /boot/EFI/Linux/nixos-generation-*.efi is signed` for all files.

---

### Step 5: Configure UEFI Secure Boot Settings

**Reboot and enter UEFI again:**

1. Press **Delete** or **F2** → **F7** (Advanced Mode)
2. Navigate to: **Boot** → **Secure Boot**
3. Configure these settings:
   - **OS Type**: Set to **"Windows UEFI mode"**
   - **Secure Boot Mode**: Set to **"Custom"** or **"User"**
4. **Save and Exit** (F10)

**Why these settings:**
- **"Windows UEFI mode"** + **"Custom"** allows both Microsoft-signed and custom-signed bootloaders
- **"Other OS"** mode may not properly enforce Secure Boot on ASUS boards

---

### Step 6: Verify Secure Boot is Active

After reboot, verify from NixOS:

```bash
# Check sbctl
sudo sbctl status
```

**Success output:**
```
Installed:    ✓ sbctl is installed
Setup Mode:   ✓ Disabled
Secure Boot:  ✓ Enabled  ← Should show ENABLED
Vendor Keys:  microsoft
```

**Also verify with:**
```bash
sudo mokutil --sb-state
# Should show: SecureBoot enabled

sudo bootctl status | grep "Secure Boot"
# Should show: Secure Boot: enabled (user)
```

---

## Verified Working Configuration (ASUS PRIME Z790-P WIFI)

**Tested UEFI Settings:**
- Motherboard: ASUS PRIME Z790-P WIFI (BIOS 1820)
- **OS Type**: Windows UEFI mode
- **Secure Boot Mode**: Custom
- **Secure Boot**: Enabled

**Key Steps:**
1. Clear all keys in UEFI → puts system in Setup Mode
2. Enroll Microsoft keys in NixOS: `sudo sbctl enroll-keys --microsoft`
3. Set UEFI to "Windows UEFI mode" + "Custom"
4. Secure Boot now works! ✅

---

## Troubleshooting

### Issue: Secure Boot Shows "Disabled" After Enabling in UEFI

**Solution:**
- Ensure **"Secure Boot Mode"** is set to **"Custom"** or **"User"**, NOT "Standard"
- "Standard" mode only accepts factory Microsoft keys and rejects custom keys
- Try changing **"OS Type"** to **"Windows UEFI mode"**

### Issue: Can't Find "Secure Boot Enable" Toggle in UEFI

**On ASUS boards:**
1. Look for **"Key Management"** submenu
2. Inside, find **"Attempt Secure Boot"** or **"Secure Boot State"**
3. Or toggle **"OS Type"** between settings to reveal hidden options

### Issue: Boot Failure with "Verification Failed" Error

**Fix:**
1. Boot with Secure Boot disabled in UEFI
2. Check for unsigned files:
   ```bash
   sudo sbctl verify
   ```
3. Sign all files:
   ```bash
   sudo sbctl sign-all
   ```
4. Re-enable Secure Boot in UEFI

### Issue: Dual-boot Windows Doesn't Work

**Ensure:**
- You used `--microsoft` flag when enrolling keys
- Windows bootloader exists: `/boot/EFI/Microsoft/Boot/bootmgfw.efi`
- UEFI boot entry for Windows exists: `sudo efibootmgr -v`

---

## Important Notes

⚠️ **Critical:**
- **systemd-boot and lanzaboote are mutually exclusive** - only enable one
- Always use `sudo sbctl enroll-keys --microsoft` for dual-boot systems
- ASUS boards require **"Custom"** Secure Boot mode, not "Standard"

🔄 **Automatic:**
- Lanzaboote signs files on every `nixos-rebuild`
- No manual signing needed after initial setup

🔑 **Backup:**
- Keys are stored in `/etc/secureboot/`
- Consider backing up this directory

---

## Quick Reference

### Essential Commands

```bash
# Check Secure Boot status
sudo sbctl status
sudo mokutil --sb-state
sudo bootctl status

# Verify signatures
sudo sbctl verify

# List all signed files
sudo sbctl list-files

# Check EFI boot entries
sudo efibootmgr -v

# Re-enroll keys (if needed)
sudo sbctl enroll-keys --microsoft
```

### File Locations

| Item | Location |
|------|----------|
| Secure Boot keys | `/etc/secureboot/` |
| Lanzaboote config | `hosts/common/bootloader.nix` |
| Signed boot files | `/boot/EFI/Linux/` |
| EFI boot entries | `/boot/EFI/BOOT/BOOTX64.EFI` |

---

## References

- [Lanzaboote GitHub](https://github.com/nix-community/lanzaboote)
- [NixOS Wiki: Secure Boot](https://nixos.wiki/wiki/Secure_Boot)
- [sbctl GitHub](https://github.com/Foxboron/sbctl)
- [UEFI Secure Boot Specification](https://uefi.org/specifications)

