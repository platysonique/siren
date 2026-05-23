#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
DEV="${DEV:-blood_hw}"

echo "Testing raw four-channel playback on $DEV"
echo "If hardware routes only one pair to phones/line, one of these should be audible."
for ch in 1 2 3 4; do
  echo
  echo "Channel $ch"
  speaker-test -D "$DEV" -c 4 -r "$RATE" -t sine -f 440 -s "$ch" -l 1 &
  pid=$!
  sleep 5
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
done

