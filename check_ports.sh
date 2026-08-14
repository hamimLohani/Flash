#!/bin/zsh

# -----------------------------
# USB Serial Port Checker
# macOS + Arduino CLI
#
# Lists raw /dev/cu.* serial devices plus arduino-cli's
# best guess at what board is attached to each one.
# -----------------------------

echo "🔎 Raw serial devices (/dev/cu.*):"
local ports=(/dev/cu.usbserial*(N) /dev/cu.usbmodem*(N) /dev/cu.SLAB_USBtoUART*(N))

if [[ ${#ports[@]} -eq 0 ]]; then
  echo "   (none found)"
else
  for p in $ports; do
    echo "   $p"
  done
fi

echo
echo "🔎 arduino-cli board list (with detected FQBN/board names):"
if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "❌ arduino-cli is not installed."
  exit 1
fi

arduino-cli board list
