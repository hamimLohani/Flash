#!/bin/zsh

# -----------------------------
# ESP32 / ESP8266 Auto Compile & Upload
# macOS + Arduino CLI
#
# Usage:
#   ./auto_upload.sh                         -> default board (esp32s3) in current dir
#   ./auto_upload.sh esp32                   -> plain ESP32
#   ./auto_upload.sh esp32s3                 -> ESP32-S3
#   ./auto_upload.sh esp32c3                 -> ESP32-C3
#   ./auto_upload.sh esp32c6                 -> ESP32-C6
#   ./auto_upload.sh esp32s2                 -> ESP32-S2
#   ./auto_upload.sh esp8266                 -> ESP8266 NodeMCU
#   ./auto_upload.sh esp32s3 /path/to/sketch -> specify board and sketch path
#   ./auto_upload.sh /path/to/sketch         -> uses default board for given sketch
#   BAUD=460800 ./auto_upload.sh             -> override upload baud rate
#   PORT=/dev/cu.usb... ./auto_upload.sh     -> override serial port
#   CDC=1 ./auto_upload.sh esp32s3           -> enable USB CDC on boot for ESP32-S3
# -----------------------------

# --- Board presets ---
typeset -A BOARD_FQBN
BOARD_FQBN=(
  esp32     "esp32:esp32:esp32"
  esp32s3   "esp32:esp32:esp32s3"
  esp32c3   "esp32:esp32:esp32c3"
  esp32c6   "esp32:esp32:esp32c6"
  esp32s2   "esp32:esp32:esp32s2"
  esp8266   "esp8266:esp8266:nodemcuv2"
)

# --- Help flag ---
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
  echo "Usage: $0 [board] [sketch_path]"
  echo
  echo "Available boards: ${(k)BOARD_FQBN}"
  echo
  echo "Examples:"
  echo "  $0                         # Default (esp32s3) in current directory"
  echo "  $0 esp32                   # ESP32 in current directory"
  echo "  $0 esp32s3 /path/to/sketch # ESP32-S3 with sketch path"
  echo "  $0 /path/to/sketch         # Default board with sketch path"
  echo
  echo "Environment variables:"
  echo "  BAUD=115200 $0             # Override upload baud rate"
  echo "  PORT=/dev/cu... $0         # Override serial port"
  echo "  CDC=1 $0 esp32s3           # Enable USB CDC on boot"
  exit 0
fi

# --- Parse arguments ---
# Check if $1 is a board key or a directory/file path
if [[ -n "$1" && -n "${BOARD_FQBN[$1]}" ]]; then
  BOARD_KEY="$1"
  TARGET="${2:-$PWD}"
elif [[ -n "$1" && (-d "$1" || -f "$1" || "$1" == *.ino) ]]; then
  BOARD_KEY="esp32s3"
  TARGET="$1"
else
  BOARD_KEY="${1:-esp32s3}"
  TARGET="${2:-$PWD}"
fi

BOARD="${BOARD_FQBN[$BOARD_KEY]}"
BAUD="${BAUD:-921600}"

# --- Resolve sketch directory ---
if [[ -f "$TARGET" && "$TARGET" == *.ino ]]; then
  SKETCH_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
elif [[ -d "$TARGET" ]]; then
  SKETCH_DIR="$(cd "$TARGET" && pwd)"
else
  echo "❌ Invalid sketch path: $TARGET"
  exit 1
fi

# --- Check arduino-cli ---
if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "❌ arduino-cli is not installed or not in PATH."
  echo "   Install via Homebrew: brew install arduino-cli"
  exit 1
fi

# --- Validate board choice ---
if [[ -z "$BOARD" ]]; then
  echo "❌ Unknown board key: $BOARD_KEY"
  echo "   Available: ${(k)BOARD_FQBN}"
  exit 1
fi

# --- Validate .ino exists in sketch directory ---
typeset -a inos
inos=("$SKETCH_DIR"/*.ino(N))
if [[ ${#inos[@]} -eq 0 ]]; then
  echo "❌ No .ino file found in $SKETCH_DIR"
  exit 1
fi

# --- Find USB serial device ---
typeset -a ports
ports=(
  /dev/cu.usbmodem*(N)
  /dev/cu.usbserial*(N)
  /dev/cu.wchusbserial*(N)
  /dev/cu.wchusb*(N)
  /dev/cu.SLAB_USBtoUART*(N)
  /dev/cu.uart*(N)
)

PORT="${PORT:-${ports[1]}}"

if [[ -z "$PORT" ]]; then
  echo "❌ No USB serial device found."
  echo
  echo "Connected boards:"
  arduino-cli board list
  exit 1
fi

# --- Board options (e.g. CDC on boot for S3/C3) ---
typeset -a compile_opts
if [[ "$CDC" == "1" && -z "$BOARD_OPTIONS" ]]; then
  BOARD_OPTIONS="CDCOnBoot=cdc"
fi

if [[ -n "$BOARD_OPTIONS" ]]; then
  compile_opts=(--board-options "$BOARD_OPTIONS")
fi

echo "🔧 Board  : $BOARD_KEY ($BOARD)"
echo "📡 Port   : $PORT"
echo "📁 Sketch : $SKETCH_DIR (${inos[1]:t})"
echo "⚡ Baud   : $BAUD"
if [[ -n "$BOARD_OPTIONS" ]]; then
  echo "⚙️  Options: $BOARD_OPTIONS"
fi
echo

# --- Compile ---
echo "🔨 Compiling..."
typeset -a compile_args
compile_args=(compile --fqbn "$BOARD")
if [[ ${#compile_opts[@]} -gt 0 ]]; then
  compile_args+=("${compile_opts[@]}")
fi
compile_args+=("$SKETCH_DIR")

if ! arduino-cli "${compile_args[@]}"; then
  echo
  echo "❌ Compilation failed."
  exit 1
fi
echo "✅ Compilation successful."
echo

# --- Upload ---
echo "⬆️  Uploading..."
if ! arduino-cli upload \
  --fqbn "$BOARD" \
  --port "$PORT" \
  --upload-field "upload.speed=$BAUD" \
  "$SKETCH_DIR"; then
  echo
  echo "❌ Upload failed."
  if [[ "$BOARD_KEY" == "esp8266" ]]; then
    echo "💡 Tip: CH340 ESP8266 boards may require lower baud: BAUD=115200 $0 $BOARD_KEY"
  else
    echo "💡 Tip: If uploading hangs, put board into bootloader mode (hold BOOT, press RESET, release BOOT)."
  fi
  exit 1
fi

echo
echo "🎉 Upload completed successfully!"
