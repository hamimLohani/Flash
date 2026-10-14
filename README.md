# ESP32 / ESP8266 Auto Compile & Upload Scripts

Zsh scripts for macOS to compile and flash Arduino sketches via `arduino-cli`,
one per board target, plus helpers to check serial ports and open serial monitors.

## Files

| Script               | Board / Role                   | FQBN / Description             |
|----------------------|--------------------------------|--------------------------------|
| `auto_upload.sh`     | Board selectable via argument  | `esp32`, `esp32s3`, `esp32c3`, `esp32c6`, `esp32s2`, `esp8266` |
| `upload_esp32.sh`    | Plain ESP32 dev board          | `esp32:esp32:esp32`            |
| `upload_esp32s3.sh`  | ESP32-S3                       | `esp32:esp32:esp32s3`          |
| `upload_esp8266.sh`  | ESP8266 NodeMCU (v2)           | `esp8266:esp8266:nodemcuv2`    |
| `check_ports.sh`     | Port detection helper          | Lists connected serial devices and highlights the active port |
| `monitor.sh`         | Serial monitor helper          | Opens serial monitor on auto-detected or specified port |
| `install.sh`         | CLI Installer                  | Copies all commands to `~/.local/bin` for system-wide use |

`auto_upload.sh` is the all-in-one script — pass the board as an argument (defaults to `esp32s3` if omitted). The `upload_*.sh` scripts are single-board versions of the same logic, split out for quick invocation without arguments.

## Global CLI Installation

To run these scripts directly from anywhere as shell commands (e.g., `upload_esp32s3`, `flash`, `check_ports`):

```zsh
./install.sh
```

This installs the commands into `~/.local/bin` (and you can also use `~/bin`).
You can then run commands directly from any terminal window without typing `./` or paths:

- `upload_esp32s3 [sketch_path]`
- `upload_esp32 [sketch_path]`
- `upload_esp8266 [sketch_path]`
- `auto_upload [board] [sketch_path]`
- `flash [board] [sketch_path]`
- `check_ports`
- `monitor [baud] [port]`

## Requirements

- macOS
- [arduino-cli](https://arduino.github.io/arduino-cli/) installed and on your `PATH`
- ESP32 (`esp32:esp32`) and/or ESP8266 (`esp8266:esp8266`) board cores installed in `arduino-cli`
- USB driver for your board's serial chip (CP2102, CH340, or native USB CDC)

---

## Setup & Prerequisites

### 1. Make all scripts executable

Run once from this directory:

```zsh
chmod +x *.sh
```

### 2. Install arduino-cli

Via Homebrew (recommended):

```zsh
brew update
brew install arduino-cli
```

Or via the official install script:

```zsh
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
```

Verify:

```zsh
arduino-cli version
```

### 3. Configure board manager URLs

Initialize the configuration (creates `~/Library/Arduino15/arduino-cli.yaml` on macOS):

```zsh
arduino-cli config init
```

Add the official ESP32 and ESP8266 package URLs:

```zsh
arduino-cli config add board_manager.additional_urls \
  https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json

arduino-cli config add board_manager.additional_urls \
  https://arduino.esp8266.com/stable/package_esp8266com_index.json

arduino-cli core update-index
```

### 4. Install the board cores

```zsh
arduino-cli core install esp32:esp32
arduino-cli core install esp8266:esp8266
```

Verify installed cores:

```zsh
arduino-cli core list
```

### 5. Install common libraries

Search for libraries anytime:

```zsh
arduino-cli lib search <name>
```

Common libraries for ESP8266 / ESP32 projects:

```zsh
arduino-cli lib install "PubSubClient"          # MQTT (HiveMQ, Mosquitto, etc.)
arduino-cli lib install "ArduinoJson"           # JSON parsing (APIs, MQTT, Firebase)
arduino-cli lib install "Firebase ESP Client"   # Firebase Auth / Realtime Database
arduino-cli lib install "Adafruit SSD1306"      # OLED displays
arduino-cli lib install "Adafruit GFX Library"  # OLED graphics core
arduino-cli lib install "Adafruit PWM Servo Driver Library"  # PCA9685 servo driver
arduino-cli lib install "DHT sensor library"    # DHT11 / DHT22 temperature sensors
arduino-cli lib install "LovyanGFX"             # High-speed display driver (ILI9341, ST7789)
```

> **Note:** `WiFi`, `FS`, `SPIFFS`, and `LittleFS` are bundled directly with the ESP core packages and do not require separate installation.

### 6. Install USB-Serial Drivers

Most dev boards use one of the following:

- **Native USB (ESP32-S3, C3, C6)**: No external driver required on macOS (`/dev/cu.usbmodem*`).
- **CP2102 / CP2104**: [Silicon Labs CP210x VCP Driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers) (`/dev/cu.usbserial*` or `/dev/cu.SLAB_USBtoUART*`).
- **CH340 / CH341**: [WCH CH34x macOS Driver](https://github.com/WCHSoftGroup/ch34xser_macos) (`/dev/cu.wchusbserial*` or `/dev/cu.usbserial*`).

Confirm detected ports anytime using:

```zsh
./check_ports.sh
```

---

## Usage

### Option A: Run inside the sketch folder

Standard Arduino layout expects a `.ino` file inside a matching directory:

```
ESP-time-lcd/
└── ESP-time-lcd.ino
```

From inside `ESP-time-lcd/`:

```zsh
# Upload using single-board scripts
/path/to/upload_esp32.sh
/path/to/upload_esp32s3.sh
/path/to/upload_esp8266.sh

# Or using auto_upload.sh (defaults to esp32s3)
/path/to/auto_upload.sh
/path/to/auto_upload.sh esp32
/path/to/auto_upload.sh esp8266
/path/to/auto_upload.sh esp32c3
```

### Option B: Pass sketch folder or file path from anywhere

You can pass the sketch folder or `.ino` file directly as an argument:

```zsh
./upload_esp32s3.sh ~/Developer/Arduino/ESP-time-lcd
./upload_esp32.sh ~/Developer/Arduino/ESP-time-lcd/ESP-time-lcd.ino

# With auto_upload.sh:
./auto_upload.sh esp32s3 ~/Developer/Arduino/ESP-time-lcd
./auto_upload.sh ~/Developer/Arduino/ESP-time-lcd
```

---

## Advanced Options & Environment Variables

### 1. Override serial port (`PORT`)

If multiple serial devices are plugged in, override the auto-detected port:

```zsh
PORT=/dev/cu.usbmodem5A7C1157311 ./upload_esp32s3.sh
PORT=/dev/cu.wchusbserial1410 ./upload_esp8266.sh
```

### 2. Override baud rate (`BAUD`)

Default upload baud rate is `921600`. If uploads fail on clone chips (especially ESP8266 with CH340), reduce to `460800` or `115200`:

```zsh
BAUD=115200 ./upload_esp8266.sh
BAUD=460800 ./upload_esp32.sh
```

### 3. ESP32-S3 Native USB CDC on Boot (`CDC=1`)

For boards where the USB cable is plugged directly into the ESP32-S3 native USB port, enable CDC-on-boot so `Serial.print()` outputs to the USB port:

```zsh
CDC=1 ./upload_esp32s3.sh
# Or pass custom board options:
BOARD_OPTIONS="CDCOnBoot=cdc" ./upload_esp32s3.sh
```

---

## Helper Scripts

### Checking Connected Ports (`check_ports.sh`)

Lists all connected serial devices and indicates which device will be auto-selected for uploads:

```zsh
./check_ports.sh
```

Sample output:
```
🔎 Raw USB serial devices (/dev/cu.*):
   👉 /dev/cu.usbmodem5A7C1157311  (default target for flash scripts)

🔎 arduino-cli board list (with detected FQBN/board names):
Port                        Protocol Type              Board Name FQBN Core
/dev/cu.usbmodem5A7C1157311 serial   Serial Port (USB) Unknown
```

### Opening the Serial Monitor (`monitor.sh`)

Opens a live serial monitor on the auto-detected or specified port:

```zsh
./monitor.sh                    # Auto-detects port, baud 115200
./monitor.sh 9600               # Auto-detects port, baud 9600
./monitor.sh 115200 /dev/cu...  # Specify baud and port
```

---

## Troubleshooting

- **"No USB serial device found"**:
  - Ensure the USB cable is a full data cable, not charge-only.
  - Run `./check_ports.sh` to check if macOS detects the serial device.
  - Confirm the CP2102 or CH340 driver is installed.

- **"Upload failed" or "A fatal error occurred: Failed to connect to ESP32"**:
  - Lower the baud rate: `BAUD=115200 ./upload_esp32.sh`.
  - Put the board into download mode manually: Hold **BOOT**, press and release **RESET** (or **EN**), then release **BOOT**.

- **"Unknown FQBN: platform esp32:esp32 is not installed"**:
  - Run `arduino-cli config add board_manager.additional_urls https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
  - Run `arduino-cli core update-index && arduino-cli core install esp32:esp32`.

- **Permission Denied when executing scripts**:
  - Run `chmod +x *.sh` in this folder.
