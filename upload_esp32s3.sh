#!/bin/zsh

# -----------------------------
# ESP32-S3 Auto Compile & Upload
# macOS + Arduino CLI
#
# Usage:
#   ./upload_esp32s3.sh              -> default baud 921600
#   BAUD=460800 ./upload_esp32s3.sh  -> override upload baud rate
# -----------------------------

BOARD="esp32:esp32:esp32s3"
BAUD="${BAUD:-921600}"
SKETCH_DIR="$PWD"

# --- Check arduino-cli ---
if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "❌ arduino-cli is not installed."
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

echo "🔧 Board  : ESP32-S3 ($BOARD)"
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
