#!/bin/zsh

# -----------------------------
# ESP32 / ESP8266 Auto Compile & Upload
# macOS + Arduino CLI
#
# Usage:
#   ./auto_upload.sh                  -> uses default board (esp32s3)
#   ./auto_upload.sh esp8266          -> uploads to ESP8266 NodeMCU
#   ./auto_upload.sh esp32s3          -> uploads to ESP32-S3
#   ./auto_upload.sh esp32            -> uploads to plain ESP32
#   BAUD=460800 ./auto_upload.sh      -> override upload baud rate
# -----------------------------

# --- Board presets: add/edit as your projects need ---
typeset -A BOARD_FQBN
BOARD_FQBN=(
  esp32     "esp32:esp32:esp32"
  esp32s3   "esp32:esp32:esp32s3"
  esp8266   "esp8266:esp8266:nodemcuv2"
)

BOARD_KEY="${1:-esp32s3}"
BOARD="${BOARD_FQBN[$BOARD_KEY]}"
BAUD="${BAUD:-921600}"

# Sketch dir = current directory (must contain a .ino file of the same name)
SKETCH_DIR="$PWD"

# --- Check arduino-cli ---
if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "❌ arduino-cli is not installed."
  exit 1
fi

# --- Validate board choice ---
if [[ -z "$BOARD" ]]; then
  echo "❌ Unknown board key: $BOARD_KEY"
  echo "   Available: ${(k)BOARD_FQBN}"
  exit 1
fi

# --- Validate sketch exists in current dir ---
if ! ls "$SKETCH_DIR"/*.ino >/dev/null 2>&1; then
  echo "❌ No .ino file found in $SKETCH_DIR"
  exit 1
fi

# --- Find the first USB serial device ---
local ports=(/dev/cu.usbserial*(N) /dev/cu.usbmodem*(N) /dev/cu.SLAB_USBtoUART*(N))
local PORT="${ports[1]}"

if [[ -z "$PORT" ]]; then
  echo "❌ No USB serial device found."
  echo
  echo "Connected boards:"
  arduino-cli board list
  exit 1
fi

echo "🔧 Board  : $BOARD_KEY ($BOARD)"
echo "📡 Port   : $PORT"
echo "📁 Sketch : $SKETCH_DIR"
echo "⚡ Baud   : $BAUD"
echo

# --- Compile ---
echo "🔨 Compiling..."
if ! arduino-cli compile \
  --fqbn "$BOARD" \
  "$SKETCH_DIR"; then
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
  exit 1
fi

echo
echo "🎉 Upload completed successfully!"
