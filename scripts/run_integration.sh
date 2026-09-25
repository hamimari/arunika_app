#!/usr/bin/env bash
# Runs every integration_test/flows/*_test.dart against a backend on the host.
# Usage: scripts/run_integration.sh <device-id> <api-base-url> [artifact-dir]
set -uo pipefail

device="${1:?device id required}"
api="${2:?api base url required}"
artifacts="${3:-artifacts}"
mkdir -p "$artifacts/screenshots"

status=0
for f in integration_test/flows/*_test.dart; do
  echo "=== $f"
  if ! flutter test "$f" --dart-define=API_BASE_URL="$api" -d "$device"; then
    status=1
    adb -s "$device" exec-out screencap -p > "$artifacts/screenshots/$(basename "$f" .dart).png" 2>/dev/null || true
  fi
done
exit $status
