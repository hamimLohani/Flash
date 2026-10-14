#!/bin/zsh

# -----------------------------
# Install Flash CLI commands
# Copies or symlinks scripts to ~/.local/bin or ~/bin
# -----------------------------

TARGET_DIR="${1:-$HOME/.local/bin}"
mkdir -p "$TARGET_DIR"

SCRIPTS=(
  auto_upload.sh
  upload_esp32.sh
  upload_esp32s3.sh
  upload_esp8266.sh
  check_ports.sh
  monitor.sh
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Installing Flash scripts to $TARGET_DIR..."

for s in "${SCRIPTS[@]}"; do
  src="$SCRIPT_DIR/$s"
  base="${s%.sh}"
  
  # Copy with .sh and without .sh extension
  cp "$src" "$TARGET_DIR/$s"
  cp "$src" "$TARGET_DIR/$base"
  chmod +x "$TARGET_DIR/$s" "$TARGET_DIR/$base"
  echo "   ✅ $base (and $s)"
done

# 'flash' command alias for auto_upload
cp "$SCRIPT_DIR/auto_upload.sh" "$TARGET_DIR/flash"
chmod +x "$TARGET_DIR/flash"
echo "   ✅ flash (alias for auto_upload)"

echo
echo "🎉 Installation complete!"
echo "You can now run commands directly from anywhere:"
echo "   upload_esp32s3 [sketch_path]"
echo "   upload_esp32   [sketch_path]"
echo "   upload_esp8266 [sketch_path]"
echo "   auto_upload    [board] [sketch_path]"
echo "   flash          [board] [sketch_path]"
echo "   check_ports"
echo "   monitor        [baud] [port]"
