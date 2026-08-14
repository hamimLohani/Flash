# ESP32 / ESP8266 Auto Compile & Upload Scripts

Zsh scripts for macOS to compile and flash Arduino sketches via `arduino-cli`,
one per board target, plus a helper to check which serial port a board is on.

## Files

| Script               | Board                          | FQBN                          |
|----------------------|---------------------------------|--------------------------------|
| `auto_upload.sh`     | Board picked via argument        | Selectable: `esp32`, `esp32s3`, `esp8266` |
| `upload_esp32.sh`    | Plain ESP32 dev board           | `esp32:esp32:esp32`            |
| `upload_esp32s3.sh`  | ESP32-S3                        | `esp32:esp32:esp32s3`          |
| `upload_esp8266.sh`  | ESP8266 NodeMCU (v2)            | `esp8266:esp8266:nodemcuv2`    |
| `check_ports.sh`     | —                                | Lists connected serial devices |

`auto_upload.sh` is the original all-in-one script — pass the board as an
argument (defaults to `esp32s3` if omitted). The `upload_*.sh` scripts are
single-board versions of the same logic, split out so you don't need to
remember the argument name per board.

## Requirements

- macOS
- [arduino-cli](https://arduino.github.io/arduino-cli/) installed and on your `PATH`
- ESP32/ESP8266 board cores installed in arduino-cli
- USB driver for your board's serial chip installed (CP2102, CH340, etc.)

## Prerequisites — install commands

### 1. Install arduino-cli

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

### 2. Initialize config and update the core index

```zsh
arduino-cli config init
arduino-cli core update-index
```

### 3. Add the ESP32/ESP8266 board manager URLs

`arduino-cli config init` creates `~/Library/Arduino15/arduino-cli.yaml`.
Add both URLs so `core update-index` can find the ESP32 and ESP8266 packages:

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

Check installed cores anytime with:

```zsh
arduino-cli core list
```

### 5. Install libraries used across your projects

Search before installing if you're unsure of the exact name:

```zsh
arduino-cli lib search <name>
```

Common libraries for your ESP8266/ESP32 projects (MQTT, Firebase, displays,
sensors, servo control):

```zsh
arduino-cli lib install "PubSubClient"          # MQTT (HiveMQ Cloud)
arduino-cli lib install "ArduinoJson"            # JSON parsing (MQTT/Firebase payloads)
arduino-cli lib install "Firebase ESP Client"    # Firebase Auth/RTDB
arduino-cli lib install "Adafruit SSD1306"       # OLED display
arduino-cli lib install "Adafruit GFX Library"   # OLED graphics dependency
arduino-cli lib install "Adafruit PWM Servo Driver Library"  # PCA9685
arduino-cli lib install "DHT sensor library"     # DHT11/DHT22
arduino-cli lib install "LovyanGFX"              # SPI display driver (ILI9341/ST7789)
```

`LittleFS` and `WiFi` come bundled with the ESP32/ESP8266 board cores, so no
separate install is needed for those.

Check installed libraries anytime with:

```zsh
arduino-cli lib list
```

### 6. Install the USB-serial driver

Most ESP32/ESP8266 dev boards use either a **CP2102** (Silicon Labs) or
**CH340/CH341** USB-to-serial chip. Install the matching macOS driver:

- CP2102: [Silicon Labs CP210x VCP driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- CH340/CH341: [WCH CH34x driver](https://github.com/WCHSoftGroup/ch34xser_macos)

After installing, reboot or re-plug the board, then confirm it shows up with
`check_ports.sh`.

## Setup

Make the scripts executable once (already done if you downloaded them from here,
but if you copy them elsewhere):

```zsh
chmod +x upload_esp32.sh upload_esp32s3.sh upload_esp8266.sh check_ports.sh
```

## Usage

Run the matching script **from inside the sketch folder** — the folder must
contain a `.ino` file with the same name as the folder (standard Arduino IDE
layout), e.g.:

```
smart_plug/
└── smart_plug.ino
```

Then, from that folder:

```zsh
# Plain ESP32
/path/to/upload_esp32.sh

# ESP32-S3
/path/to/upload_esp32s3.sh

# ESP8266 NodeMCU
/path/to/upload_esp8266.sh

# Or, using the single combined script with a board argument:
/path/to/auto_upload.sh esp32      # plain ESP32
/path/to/auto_upload.sh esp32s3    # ESP32-S3 (default if no argument given)
/path/to/auto_upload.sh esp8266    # ESP8266 NodeMCU
```

Each script will:
1. Confirm `arduino-cli` is installed
2. Confirm a `.ino` file exists in the current folder
3. Auto-detect the first connected `/dev/cu.usbserial*`, `/dev/cu.usbmodem*`,
   or `/dev/cu.SLAB_USBtoUART*` device
4. Compile the sketch for that board
5. Upload it over the detected port

### Override the upload baud rate

Default is `921600`. Override with the `BAUD` env var if uploads are unreliable
(common on some ESP8266 CH340 clones — try `115200` or `460800`):

```zsh
BAUD=115200 /path/to/upload_esp8266.sh
BAUD=115200 /path/to/auto_upload.sh esp8266
```

### Checking ports first

If you're not sure which port your board enumerated on, or which board is
plugged in, run:

```zsh
/path/to/check_ports.sh
```

This prints the raw `/dev/cu.*` serial devices found, plus `arduino-cli`'s own
guess at the board/FQBN attached to each — handy when you have more than one
board connected at once.

## Troubleshooting

- **"No USB serial device found"** — check the cable (some are charge-only),
  run `check_ports.sh`, and confirm the CP2102/CH340 driver is installed.
- **Compilation failed** — check the sketch compiles in Arduino IDE first;
  the error output from `arduino-cli compile` will point to the file/line.
- **Upload failed / times out** — try a lower `BAUD` value, or hold the
  board's BOOT button during the "Connecting..." phase (needed on some
  ESP32-S3 boards without auto-reset circuitry).
- **Multiple boards connected** — the scripts grab the *first* matching port.
  Unplug the other board, or edit the script to hardcode the exact
  `/dev/cu.*` path from `check_ports.sh`.
