#!/usr/bin/env bash
#
# tools/capture-screenshots.sh
#
# Captures one App Store screenshot from an already-booted, already-
# provisioned iOS Simulator, and verifies the resulting PNG's pixel
# dimensions with `sips`. See docs/app-store-screenshots.md for the full
# procedure, prerequisites, and the current required sizes.
#
# This script assumes all prerequisites are already met at the moment you
# run it for a given shot: the target simulator is booted, the app is
# running (`flutter run --release`), the model has finished downloading,
# and the UI is already sitting in the state you want captured. It does
# not drive the app's UI for you.
#
# Usage:
#   tools/capture-screenshots.sh <device-name> <output-name> <WIDTHxHEIGHT>
#
# Example:
#   tools/capture-screenshots.sh "Ash Screenshots 6.9in" 01-home 1320x2868
#
# Exit codes:
#   0  captured and dimensions matched
#   1  bad usage / device not booted
#   2  captured but dimensions did NOT match (PNG is left in place so you
#      can inspect it — this usually means the wrong device, a resized
#      simulator window, or a stale expected size)

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <device-name> <output-name-without-extension> <WIDTHxHEIGHT>" >&2
  echo 'Example: '"$0"' "Ash Screenshots 6.9in" 01-home 1320x2868' >&2
  exit 1
fi

DEVICE="$1"
NAME="$2"
EXPECTED="$3"
EXPECTED_W="${EXPECTED%x*}"
EXPECTED_H="${EXPECTED#*x}"

if [[ "$EXPECTED_W" == "$EXPECTED" || -z "$EXPECTED_H" ]]; then
  echo "ERROR: expected size '$EXPECTED' must look like WIDTHxHEIGHT, e.g. 1320x2868" >&2
  exit 1
fi

OUT_DIR="build/screenshots"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${NAME}.png"

if ! xcrun simctl list devices | grep -F "$DEVICE" | grep -q "Booted"; then
  echo "ERROR: simulator '$DEVICE' does not appear to be booted." >&2
  echo "Boot it and get the app into the right on-screen state before" >&2
  echo "calling this script — it does not navigate the UI for you." >&2
  echo "  xcrun simctl boot \"$DEVICE\"" >&2
  exit 1
fi

echo "Capturing '$NAME' from '$DEVICE' -> $OUT_FILE"
xcrun simctl io "$DEVICE" screenshot "$OUT_FILE"

ACTUAL_W=$(sips -g pixelWidth "$OUT_FILE" | awk '/pixelWidth:/{print $2}')
ACTUAL_H=$(sips -g pixelHeight "$OUT_FILE" | awk '/pixelHeight:/{print $2}')

echo "  captured: ${ACTUAL_W}x${ACTUAL_H}   expected: ${EXPECTED_W}x${EXPECTED_H}"

if [[ "$ACTUAL_W" != "$EXPECTED_W" || "$ACTUAL_H" != "$EXPECTED_H" ]]; then
  echo "MISMATCH: $OUT_FILE is ${ACTUAL_W}x${ACTUAL_H}, expected ${EXPECTED_W}x${EXPECTED_H}." >&2
  echo "Apple will reject this at upload. Common causes: wrong simulator" >&2
  echo "device class, a manually resized Simulator window, or a stale" >&2
  echo "expected size — re-check docs/app-store-screenshots.md and the" >&2
  echo "live App Store Connect screenshot spec before retrying." >&2
  exit 2
fi

echo "  OK: $OUT_FILE matches ${EXPECTED_W}x${EXPECTED_H}"
