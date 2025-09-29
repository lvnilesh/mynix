#!/usr/bin/env bash

# Brother HL-4070 Printer Setup Script
# Configures the printer with monochrome only, Letter size, and duplex printing

set -euo pipefail

PRINTER_NAME="Brother_HL-4070"
PRINTER_URI="ipp://brother.cg.home.arpa:631/ipp"

echo "🖨️  Setting up Brother HL-4070 laser printer..."

# Check if CUPS is running
if ! systemctl is-active --quiet cups; then
    echo "Starting CUPS service..."
    sudo systemctl start cups
    sleep 2
fi

# Test printer connectivity first
echo "Testing printer connectivity..."
if ! ping -c 2 -W 5 brother.cg.home.arpa &>/dev/null; then
    echo "⚠️  Warning: Cannot ping brother.cg.home.arpa"
    echo "   Make sure the printer is powered on and connected to network"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting setup."
        exit 1
    fi
fi

# Remove existing printer if it exists
if lpstat -p "$PRINTER_NAME" &>/dev/null; then
    echo "Removing existing printer configuration..."
    sudo lpadmin -x "$PRINTER_NAME" || true
fi

# Find the correct PPD file for Brother laser printers
echo "Looking for Brother PPD files..."
PPD_PATH=""

# Try different possible locations for Brother PPD files
for pattern in \
    "*/cups*/model/*brother*" \
    "*/cups*/model/*Brother*" \
    "*/share/cups/model/*" \
    "*/brlaser/*" \
    "*GenML*"; do

    PPD_PATH=$(find /nix/store -name "*.ppd" -path "$pattern" 2>/dev/null | head -1)
    if [[ -n "$PPD_PATH" ]]; then
        echo "✅ Found PPD file: $PPD_PATH"
        break
    fi
done

# Add the printer with fallback options
echo "Adding Brother HL-4070 printer..."
if [[ -n "$PPD_PATH" ]]; then
    # Use found PPD file
    sudo lpadmin -p "$PRINTER_NAME" \
        -v "$PRINTER_URI" \
        -E \
        -P "$PPD_PATH" \
        -L "Brother HL-4070 Laser Printer" \
        -D "Brother HL-4070 Monochrome Laser Printer with Duplex"
else
    # Fallback: let CUPS auto-detect or use generic driver
    echo "⚠️  No specific PPD found, using auto-detection..."
    sudo lpadmin -p "$PRINTER_NAME" \
        -v "$PRINTER_URI" \
        -E \
        -L "Brother HL-4070 Laser Printer" \
        -D "Brother HL-4070 Monochrome Laser Printer with Duplex"
fi

# Enable and accept jobs for this printer
echo "Enabling printer..."
sudo cupsenable "$PRINTER_NAME" || true
sudo cupsaccept "$PRINTER_NAME" || true

# Set as default printer
echo "Setting as default printer..."
sudo lpadmin -d "$PRINTER_NAME" || true

# Wait for printer to be ready
sleep 3

# Configure printer options for monochrome, Letter size, and duplex
echo "Configuring printer options..."

# Apply settings with error handling
apply_setting() {
    local setting="$1"
    local description="$2"
    echo "  Setting $description..."
    if sudo lpadmin -p "$PRINTER_NAME" -o "$setting"; then
        echo "    ✅ $description applied"
    else
        echo "    ⚠️  $description may not be supported"
    fi
}

# Apply all settings
apply_setting "ColorModel=Gray" "monochrome mode"
apply_setting "PageSize=Letter" "Letter paper size"
apply_setting "Duplex=DuplexNoTumble" "duplex printing"

# Check available resolutions and set maximum
echo "  Checking available resolutions..."
AVAILABLE_RESOLUTIONS=$(lpoptions -p "$PRINTER_NAME" -l 2>/dev/null | grep -i resolution || echo "")
if echo "$AVAILABLE_RESOLUTIONS" | grep -q "2400x600dpi"; then
    apply_setting "Resolution=2400x600dpi" "maximum resolution (2400x600 DPI)"
elif echo "$AVAILABLE_RESOLUTIONS" | grep -q "1200dpi"; then
    apply_setting "Resolution=1200dpi" "high resolution (1200 DPI)"
else
    apply_setting "Resolution=600dpi" "standard resolution (600 DPI)"
fi

# Additional quality settings
apply_setting "TonerSave=Off" "toner save off"

# Brother-specific options (may not all be available)
apply_setting "BrCopies=1" "Brother copies setting" 2>/dev/null || true
apply_setting "BrHalftonePattern=Enhanced" "Brother halftone pattern" 2>/dev/null || true

# Restart CUPS to apply changes
echo "Restarting CUPS service..."
sudo systemctl restart cups

# Wait for service to restart
sleep 3
# Verify printer setup
echo ""
echo "🎯 Printer Setup Complete!"
echo "================================"
echo "Printer Name: $PRINTER_NAME"
echo "URI: $PRINTER_URI"

# Check if printer is default
if lpstat -d 2>/dev/null | grep -q "$PRINTER_NAME"; then
    echo "Default: ✅ Yes"
else
    echo "Default: ❌ No"
fi

# Show current configuration
echo ""
echo "Current Configuration:"
if command -v lpoptions >/dev/null; then
    CURRENT_OPTIONS=$(lpoptions -p "$PRINTER_NAME" 2>/dev/null || echo "Unable to retrieve options")
    echo "  📄 Paper Size: $(echo "$CURRENT_OPTIONS" | grep -o 'PageSize=[^[:space:]]*' | cut -d= -f2 || echo "Unknown")"
    echo "  🖤 Color Mode: $(echo "$CURRENT_OPTIONS" | grep -o 'ColorModel=[^[:space:]]*' | cut -d= -f2 || echo "Unknown")"
    echo "  📋 Duplex: $(echo "$CURRENT_OPTIONS" | grep -o 'Duplex=[^[:space:]]*' | cut -d= -f2 || echo "Unknown")"
    echo "  🎯 Resolution: $(echo "$CURRENT_OPTIONS" | grep -o 'Resolution=[^[:space:]]*' | cut -d= -f2 || echo "Unknown")"
fi

echo ""
echo "Printer Status:"
if lpstat -p "$PRINTER_NAME" 2>/dev/null; then
    echo "✅ Printer is accessible"
else
    echo "⚠️  Printer status unknown"
fi

echo ""
echo "✅ Brother HL-4070 setup completed!"
echo ""
echo "📋 Test commands:"
echo "  echo 'Test print' | lp -d $PRINTER_NAME     # Quick test"
echo "  lp -d $PRINTER_NAME /etc/hostname          # Print hostname"
echo "  lpstat -t                                   # Check all printer status"
echo "  lpoptions -p $PRINTER_NAME -l              # Show all printer options"
echo "  system-config-printer                      # GUI configuration"
echo ""
echo "🖨️  Your Brother HL-4070 is ready for high-quality printing!"
