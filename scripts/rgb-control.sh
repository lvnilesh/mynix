#!/usr/bin/env bash

# Quick RGB Control Helper for ASUS PRIME Z790-P WIFI
# Usage: ./rgb-control.sh [color|off|red|green|blue|white]

set_rgb() {
    local color="$1"
    echo "Setting RGB to: $color"
    for channel in led1 led2 led3 led4; do
        liquidctl --match "ASUS" set "$channel" color static "$color" || {
            echo "Failed to set $channel"
        }
    done
    echo "RGB update complete"
}

case "${1:-help}" in
    "off"|"black")
        set_rgb "000000"
        ;;
    "red")
        set_rgb "FF0000"
        ;;
    "green")
        set_rgb "00FF00"
        ;;
    "blue")
        set_rgb "0000FF"
        ;;
    "white")
        set_rgb "FFFFFF"
        ;;
    "yellow")
        set_rgb "FFFF00"
        ;;
    "purple")
        set_rgb "FF00FF"
        ;;
    "cyan")
        set_rgb "00FFFF"
        ;;
    "off2"|"disable")
        # Try using off mode instead of black color
        echo "Setting RGB to: off mode"
        for channel in led1 led2 led3 led4; do
            liquidctl --match "ASUS" set "$channel" color off || {
                echo "Failed to set $channel to off mode"
            }
        done
        echo "RGB disable complete"
        ;;
    [0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
        set_rgb "$1"
        ;;
    *)
        echo "RGB Control for ASUS PRIME Z790-P WIFI"
        echo ""
        echo "Usage: $0 [color]"
        echo ""
        echo "Colors:"
        echo "  off/black  - Turn off RGB (very dark)"
        echo "  off2/disable - Try off mode instead"
        echo "  red        - Red color"
        echo "  green      - Green color"
        echo "  blue       - Blue color"
        echo "  white      - White color"
        echo "  yellow     - Yellow color"
        echo "  purple     - Purple color"
        echo "  cyan       - Cyan color"
        echo "  RRGGBB     - Custom hex color (e.g., FF8000)"
        echo ""
        echo "Examples:"
        echo "  $0 white"
        echo "  $0 FF8000"
        echo "  $0 off"
        ;;
esac
