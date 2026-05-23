#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
"${ROOT}/refresh-bloodsiren.sh"

echo ""
echo "=== ALSA devices ==="
aplay -l | grep -i HIFI || true
arecord -l | grep -i HIFI || true
echo ""
echo "=== Virtual PCMs ==="
aplay -L | grep -E '^bloodsiren|^blood_playback' || true
echo ""
echo "=== 8ch capture (2 sec) ==="
timeout 2 arecord -D bloodsiren_in -c 8 -r 48000 -f S24_3LE -d 2 /dev/null
echo "OK"
echo ""
echo "=== stereo playback (2 sec) ==="
timeout 2 aplay -D blood_playback -c 2 -r 48000 -f S24_3LE -d 2 /dev/zero
echo "OK"
echo ""
echo "=== tone on blood (listen on blood unit headphones) ==="
timeout 3 speaker-test -D blood_playback -c 2 -r 48000 -t sine -l 1
echo ""
echo "All CLI tests passed. Quit Waveform before running this."
