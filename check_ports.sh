#!/bin/zsh

# -----------------------------
# USB Serial Port Checker
# macOS + Arduino CLI
#
# Lists raw /dev/cu.* serial devices plus arduino-cli's
# detected board names and FQBNs.
# -----------------------------

echo "🔎 Raw USB serial devices (/dev/cu.*):"
typeset -a ports
ports=(
  /dev/cu.usbmodem*(N)
  /dev/cu.usbserial*(N)
  /dev/cu.wchusbserial*(N)
  /dev/cu.wchusb*(N)
  /dev/cu.SLAB_USBtoUART*(N)
  /dev/cu.uart*(N)
)

if [[ ${#ports[@]} -eq 0 ]]; then
  echo "   (none found)"
  echo "   💡 Check USB cable (data-capable) and USB-to-UART driver (CP210x / CH340)."
else
  for p in "${ports[@]}"; do
    if [[ "$p" == "${ports[1]}" ]]; then
      echo "   👉 $p  (default target for flash scripts)"
    else
      echo "      $p"
    fi
  done
fi

echo
echo "🔎 arduino-cli board list (with detected FQBN/board names):"
if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "⚠️  arduino-cli is not installed or not in PATH."
else
  arduino-cli board list
fi
