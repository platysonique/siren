#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
RECORD_SECS="${RECORD_SECS:-10}"
FMT="${FMT:-S24_3LE}"
OUT="${OUT:-/tmp/bloodsiren-8ch-test.wav}"

echo "Recording ${RECORD_SECS} sec from bloodsiren_in to $OUT"
arecord -D bloodsiren_in -c 8 -r "$RATE" -f "$FMT" -d "$RECORD_SECS" "$OUT"
echo "OK: $OUT"

