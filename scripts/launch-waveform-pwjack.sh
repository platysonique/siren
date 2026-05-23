#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
BLOCK="${BLOCK:-256}"

export PIPEWIRE_LATENCY="${BLOCK}/${RATE}"
export PW_KEY_NODE_RATE="1/${RATE}"

if command -v pw-jack >/dev/null; then
  if command -v Waveform13 >/dev/null; then
    exec pw-jack Waveform13
  fi
  if command -v waveform13 >/dev/null; then
    exec pw-jack waveform13
  fi
  if [[ -x "/usr/bin/Waveform13" ]]; then
    exec pw-jack /usr/bin/Waveform13
  fi
  echo "Could not find Waveform13 binary. Run manually like:"
  echo "  PIPEWIRE_LATENCY=$PIPEWIRE_LATENCY pw-jack /path/to/Waveform13"
  exit 1
else
  echo "pw-jack not found. Install pipewire-jack or launch Waveform normally."
  exit 1
fi

