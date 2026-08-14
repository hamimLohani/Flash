#!/bin/zsh

# -----------------------------
# ESP8266 NodeMCU Auto Compile & Upload
# macOS + Arduino CLI
#
# Usage:
#   ./upload_esp8266.sh              -> default baud 921600
#   BAUD=115200 ./upload_esp8266.sh  -> override upload baud rate
#     (ESP8266 clones on CH340 can be flaky above 460800 - drop baud if uploads fail)
# -----------------------------

BOARD="esp8266:esp8266:nodemcuv2"
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

echo "🔧 Board  : ESP8266 NodeMCU ($BOARD)"
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
