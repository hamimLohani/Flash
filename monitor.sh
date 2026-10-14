#!/bin/zsh

# -----------------------------
# Serial Monitor Helper
# macOS + Arduino CLI
#
# Usage:
#   ./monitor.sh                      -> auto-detects port, baud 115200
#   ./monitor.sh 9600                 -> auto-detects port, baud 9600
#   ./monitor.sh 115200 /dev/cu.usb...-> specify baud and port
#   BAUD=115200 ./monitor.sh          -> specify baud via env var
#   PORT=/dev/cu.usb... ./monitor.sh  -> specify port via env var
# -----------------------------

# --- Parse arguments ---
# Check if $1 is a baud rate or a port
if [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]; then
  BAUD="$1"
  PORT="${2:-$PORT}"
elif [[ -n "$1" && "$1" == /dev/cu.* ]]; then
  PORT="$1"
  BAUD="${2:-${BAUD:-115200}}"
else
  BAUD="${BAUD:-115200}"
fi

# --- Find USB serial device if not specified ---
if [[ -z "$PORT" ]]; then
  typeset -a ports
  ports=(
    /dev/cu.usbmodem*(N)
    /dev/cu.usbserial*(N)
    /dev/cu.wchusbserial*(N)
    /dev/cu.wchusb*(N)
    /dev/cu.SLAB_USBtoUART*(N)
    /dev/cu.uart*(N)
  )
  PORT="${ports[1]}"
fi

if [[ -z "$PORT" ]]; then
  echo "❌ No USB serial device found."
  exit 1
fi

echo "📡 Opening Serial Monitor on $PORT @ $BAUD baud..."
echo "💡 Press Ctrl+C to exit."
echo

if command -v arduino-cli >/dev/null 2>&1; then
  arduino-cli monitor -p "$PORT" -c "baudrate=$BAUD"
elif command -v screen >/dev/null 2>&1; then
  screen "$PORT" "$BAUD"
else
  echo "❌ Neither arduino-cli nor screen is installed to open monitor."
  exit 1
fi
