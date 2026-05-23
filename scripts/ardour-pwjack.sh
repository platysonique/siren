#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
BLOCK="${BLOCK:-256}"
export PIPEWIRE_LATENCY="${BLOCK}/${RATE}"

if command -v ardour8 >/dev/null; then
  exec pw-jack ardour8
elif command -v ardour7 >/dev/null; then
  exec pw-jack ardour7
elif command -v ardour >/dev/null; then
  exec pw-jack ardour
else
  echo "Ardour not found."
  exit 1
fi

