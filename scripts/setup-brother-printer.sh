#!/usr/bin/env bash

# Brother HL-4070CDW Direct Printer Setup
# Configures direct IPP connection bypassing cosmos AirPrint server
# Monochrome default (change ColorModel=CMYK when color toners are installed)

set -euo pipefail

PRINTER_NAME="Brother-Direct"
PRINTER_URI="ipp://brother.cg.home.arpa:631/ipp"

echo "Setting up $PRINTER_NAME..."

# Ensure CUPS is running
if ! systemctl is-active --quiet cups; then
    echo "Starting CUPS..."
    sudo systemctl start cups
    sleep 2
fi

# Test connectivity
if ! ping -c 2 -W 5 brother.cg.home.arpa &>/dev/null; then
    echo "Warning: Cannot reach brother.cg.home.arpa"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# Remove existing if present
lpstat -p "$PRINTER_NAME" &>/dev/null && sudo lpadmin -x "$PRINTER_NAME"

# Find Brother driver model string via lpinfo
echo "Finding driver..."
MODEL=$(lpinfo -m 2>/dev/null | grep -i "brlaser.*4070\|gutenprint.*Brother.*HL-4" | head -1 | awk '{print $1}')

if [[ -n "$MODEL" ]]; then
    echo "Using driver: $MODEL"
    sudo lpadmin -p "$PRINTER_NAME" \
        -v "$PRINTER_URI" \
        -E \
        -m "$MODEL" \
        -L "Garage" \
        -D "Brother HL-4070CDW Direct"
else
    echo "No specific driver found, using auto-detection..."
    sudo lpadmin -p "$PRINTER_NAME" \
        -v "$PRINTER_URI" \
        -E \
        -L "Garage" \
        -D "Brother HL-4070CDW Direct"
fi

# Enable and accept jobs
sudo cupsenable "$PRINTER_NAME" 2>/dev/null || true
sudo cupsaccept "$PRINTER_NAME" 2>/dev/null || true

sleep 2

# Apply defaults: monochrome, letter, duplex
echo "Applying defaults..."
apply() {
    sudo lpadmin -p "$PRINTER_NAME" -o "$1" 2>/dev/null && echo "  $1" || echo "  $1 (not supported)"
}

apply "ColorModel=Gray"
apply "PageSize=Letter"
apply "Duplex=DuplexNoTumble"

# Try best available resolution
RESOLUTIONS=$(lpoptions -p "$PRINTER_NAME" -l 2>/dev/null | grep -i resolution || true)
if echo "$RESOLUTIONS" | grep -q "2400x600"; then
    apply "Resolution=2400x600dpi"
elif echo "$RESOLUTIONS" | grep -q "1200"; then
    apply "Resolution=1200dpi"
else
    apply "Resolution=600dpi"
fi

echo ""
echo "Done. Printer: $PRINTER_NAME"
echo "  URI: $PRINTER_URI"
echo "  Mode: Monochrome (change to CMYK when color toners installed)"
echo ""
echo "Test: echo 'test' | lp -d $PRINTER_NAME"
echo "Status: lpstat -p $PRINTER_NAME"
