#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "bloodsiren setup"
echo "================"

"${ROOT}/refresh-bloodsiren.sh"

UDEV_SRC="${ROOT}/99-hifi-audio-dual.rules"
UDEV_DST="/etc/udev/rules.d/99-hifi-audio-dual.rules"

if [[ ! -f "$UDEV_DST" ]]; then
  echo
  echo "Installing udev rules (requires sudo)..."
  sudo cp "$UDEV_SRC" "$UDEV_DST"
  sudo udevadm control --reload-rules
  sudo udevadm trigger -c add -s sound
  echo "udev rules installed. Card names will stabilize as blood / siren."
else
  echo
  echo "udev rules already installed at $UDEV_DST"
fi

echo
echo "Restarting PipeWire..."
systemctl --user restart wireplumber pipewire pipewire-pulse
sleep 2

echo
echo "USB hub layout:"
lsusb -t 2>/dev/null | grep -A6 'Port 002: Dev.*Hub' | head -10 || true

echo
echo "ALSA cards:"
cat /proc/asound/cards

echo
echo "bloodsiren status:"
arecord -L | grep -E '^bloodsiren_in$' && echo "  ALSA in: OK" || echo "  ALSA in: missing"
aplay -L | grep -E '^bloodsiren_out$' && echo "  ALSA out: OK" || echo "  ALSA out: missing"
pactl list sources short | grep combine_source_bloodsiren && echo "  PipeWire: OK" || echo "  PipeWire: missing"

echo
echo "Waveform (quit and reopen after running this script):"
echo "  Input:  bloodsiren_in (8 ch @ 48000 Hz)"
echo "  Output: blood_playback (2 ch stereo on blood — NOT bloodsiren duplex)"
echo "  Tracks 1-4 = blood, 5-8 = siren. Default headphones = blood unit only."
echo "  Per-unit stereo out: blood_playback / siren_playback"
echo
echo "Headphones / direct outs:"
echo "  Linux only sees one 4-channel playback stream per interface."
echo "  Use each unit's front-panel knobs to route phones/direct outs in hardware."
echo "Test: arecord -D bloodsiren_in -c 8 -r 48000 -f S24_3LE -d 5 test-8ch.wav"
echo "Reset Waveform prefs: ${ROOT}/waveform-audio-reset.sh"
echo
echo "Unit map (always use the same hub ports):"
echo "  Hub port 3 -> blood  -> Waveform tracks 1-4"
echo "  Hub port 4 -> siren  -> Waveform tracks 5-8"
echo "  Identify: ${ROOT}/identify-units.sh"
echo "  - Use a powered hub if you get dropouts"
echo "  - After moving cables, run: ${ROOT}/refresh-bloodsiren.sh"
