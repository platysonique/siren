#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
DURATION="${DURATION:-8}"
DEV="${DEV:-blood_playback}"

echo "Playing stereo test into $DEV at $RATE Hz"
speaker-test -D "$DEV" -c 2 -r "$RATE" -t sine -f 440 -l 1 &
pid=$!
sleep "$DURATION"
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
echo "Done"

