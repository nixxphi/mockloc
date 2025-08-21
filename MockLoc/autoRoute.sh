#!/bin/bash
# Auto-run GPX routes on Android Emulator
# Scans ./routes folder, selects routes based on time/day, and replays them.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"   # project root
ROUTES_DIR="$BASE_DIR/routes"
SERIAL_ARG=""

# --- helper: pick first emulator ---
pick_emulator() {
  EMU=$(adb devices | awk '/^emulator-/{print $1; exit}')
  if [ -z "$EMU" ]; then
    echo "No Android emulator detected. Start an AVD first."
    exit 1
  fi
  echo "$EMU"
}

# --- helper: choose route based on time/day ---
pick_route() {
  DAY=$(date +%u)    # 1=Mon ... 7=Sun
  HOUR=$(date +%H)   # 00-23

  if [ $DAY -le 5 ]; then
    # Weekday
    if [ $HOUR -ge 7 ] && [ $HOUR -lt 10 ]; then
      echo "$ROUTES_DIR/weekday/commute.gpx"
    elif [ $HOUR -ge 12 ] && [ $HOUR -lt 14 ]; then
      echo "$ROUTES_DIR/weekday/lunchBreak.gpx"
    elif [ $HOUR -ge 17 ] && [ $HOUR -lt 19 ]; then
      echo "$ROUTES_DIR/weekday/commuteHome.gpx"
    else
      echo "$ROUTES_DIR/random/randomStroll.gpx"
    fi
  else
    # Weekend
    if [ $HOUR -ge 10 ] && [ $HOUR -lt 14 ]; then
      echo "$ROUTES_DIR/weekend/brunchTrip.gpx"
    elif [ $HOUR -ge 18 ] && [ $HOUR -lt 23 ]; then
      echo "$ROUTES_DIR/weekend/nightOut.gpx"
    else
      echo "$ROUTES_DIR/random/randomStroll.gpx"
    fi
  fi
}

# --- main ---
EMU=$(pick_emulator)
SERIAL_ARG="-s $EMU"

ROUTE_FILE=$(pick_route)

if [ ! -f "$ROUTE_FILE" ]; then
  echo "No GPX found for current schedule: $ROUTE_FILE"
  exit 1
fi

echo "Using emulator: $EMU"
echo "Running route: $ROUTE_FILE"

adb $SERIAL_ARG emu geo track stop || true
adb $SERIAL_ARG emu geo track start "$ROUTE_FILE"
echo "Route started."
