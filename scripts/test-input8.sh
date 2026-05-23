#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
RECORD_SECS="${RECORD_SECS:-10}"
FMT="${FMT:-S24_3LE}"

detect_in_channels() {
  local ch
  ch=$(arecord -D bloodsiren_in --dump-hw-params 2>/dev/null | awk '/^CHANNELS:/ {print $2; exit}' | tr -d '[:space:]')
  if [[ -n "$ch" && "$ch" =~ ^[0-9]+$ ]]; then
    echo "$ch"
    return 0
  fi
  echo 4
}

CHANNELS="${CHANNELS:-$(detect_in_channels)}"
if [[ "$CHANNELS" -lt 8 ]]; then
  echo "bloodsiren_in has ${CHANNELS} channel(s) — 8ch needs a second HIFI unit on HUB_PORT_SIREN."
fi

OUT="${OUT:-/tmp/bloodsiren-${CHANNELS}ch-test.wav}"

echo "Recording ${RECORD_SECS} sec from bloodsiren_in (${CHANNELS} ch) to $OUT"
arecord -D bloodsiren_in -c "$CHANNELS" -r "$RATE" -f "$FMT" -d "$RECORD_SECS" "$OUT"
echo "OK: $OUT"
