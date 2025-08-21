#!/bin/bash
# Replay a GPX file on the ANDROID EMULATOR with adb.
# Usage: ./utils/runRoute.sh <path/to/route.gpx> [--serial emulator-5554]

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path/to/route.gpx> [--serial emulator-5554]"
  exit 1
fi

GPX_INPUT="$1"; shift || true
SERIAL_ARG=""

# Optional --serial
if [ "${1-}" = "--serial" ] && [ -n "${2-}" ]; then
  SERIAL_ARG="-s $2"
  shift 2
fi

# Ensure adb is available
if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found in PATH. Install Android Platform Tools and try again."
  exit 1
fi

# Resolve absolute path (supports spaces)
if command -v realpath >/dev/null 2>&1; then
  GPX_FILE="$(realpath "$GPX_INPUT")"
else
  # Fallback
  GPX_FILE="$(cd "$(dirname "$GPX_INPUT")" && pwd)/$(basename "$GPX_INPUT")"
fi

if [ ! -f "$GPX_FILE" ]; then
  echo "GPX file not found: $GPX_FILE"
  exit 1
fi

# If no serial provided, auto-pick the first emulator
if [ -z "$SERIAL_ARG" ]; then
  EMU=$(adb devices | awk '/^emulator-/{print $1; exit}')
  if [ -z "$EMU" ]; then
    echo "No Android emulator detected. Start an emulator first (AVD), or pass --serial emulator-5554."
    exit 1
  fi
  SERIAL_ARG="-s $EMU"
fi

# Verify target is actually an emulator
TARGET=$(echo "$SERIAL_ARG" | awk '{print $2}')
if [[ "$TARGET" != emulator-* ]]; then
  echo "Selected device is not an emulator ($TARGET). 'adb emu geo track' works only on the emulator."
  exit 1
fi

echo "Using emulator: $TARGET"
echo "Replaying route from: $GPX_FILE"

# Stop any previous track (ignore errors), then start this one
adb $SERIAL_ARG emu geo track stop || true
adb $SERIAL_ARG emu geo track start "$GPX_FILE"
echo "Started track."
