#!/bin/zsh

# -----------------------------
# ESP8266 NodeMCU Auto Compile & Upload
# macOS + Arduino CLI
#
# Usage:
#   ./upload_esp8266.sh                      -> compiles current directory & uploads
#   ./upload_esp8266.sh /path/to/sketch      -> compiles target sketch & uploads
#   BAUD=115200 ./upload_esp8266.sh          -> override upload baud rate (recommended for CH340 clones)
#   PORT=/dev/cu.wchusbserial... ./upload_esp8266.sh -> override serial port
# -----------------------------

BOARD="esp8266:esp8266:nodemcuv2"
BAUD="${BAUD:-921600}"

# --- Resolve sketch directory ---
TARGET="${1:-$PWD}"
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
  /dev/cu.usbserial*(N)
  /dev/cu.wchusbserial*(N)
  /dev/cu.wchusb*(N)
  /dev/cu.SLAB_USBtoUART*(N)
  /dev/cu.usbmodem*(N)
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

echo "🔧 Board  : ESP8266 NodeMCU ($BOARD)"
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
if [[ -n "$BOARD_OPTIONS" ]]; then
  compile_args+=(--board-options "$BOARD_OPTIONS")
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
  echo "💡 Tip: ESP8266 boards with CH340 chips frequently fail at 921600 baud."
  echo "   Try lowering the baud rate: BAUD=115200 $0"
  exit 1
fi

echo
echo "🎉 Upload completed successfully!"
