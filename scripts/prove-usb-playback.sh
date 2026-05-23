#!/usr/bin/env bash
# Prove whether PCM actually reaches the USB HIFI AUDIO playback endpoint.
# Run with Waveform CLOSED: pkill -x Waveform13
set -euo pipefail

CARD="${1:-3}"
SECONDS="${2:-60}"
DEV="/proc/asound/card${CARD}/pcm0p/sub0/status"
NAME=$(awk -v c="$CARD" '$1==c {print $2; exit}' /proc/asound/cards | tr -d '[]')
PCM="hw:${NAME},0"

python3 <<PY
import math, struct, wave
rate = 48000
dur = float("${SECONDS}")
freq = 440
path = "/tmp/prove-usb-4ch.wav"
n = int(rate * dur)
with wave.open(path, "w") as w:
    w.setnchannels(4)
    w.setsampwidth(2)
    w.setframerate(rate)
    frames = bytearray()
    for i in range(n):
        s = int(32767 * 0.95 * math.sin(2 * math.pi * freq * i / rate))
        frames += struct.pack("<hhhh", s, s, s, s)
    w.writeframes(frames)
print(f"/tmp/prove-usb-4ch.wav ready ({dur:.0f} sec, 440 Hz, ALL 4 channels full scale)")
PY

echo ""
echo "=== USB playback proof on card ${CARD} (${NAME}) — ${SECONDS}s tone ==="
echo "If hw_ptr increases while state=RUNNING, Linux IS sending audio over USB."
echo "USB descriptors on this device: Speaker + Line Connector (not separate ALSA jacks)."
echo "Listen on: ALL line/direct outputs AND both headphone jacks on the unit."
echo ""

if pgrep -x Waveform13 >/dev/null; then
  echo "WARNING: Waveform is running and may block playback. Run: pkill -x Waveform13"
fi

PCM="hw:${NAME},0"

aplay -D "$PCM" -c 4 -r 48000 /tmp/prove-usb-4ch.wav &
PID=$!
sleep 0.4
if [[ -f "$DEV" ]]; then
  echo "--- /proc/asound status during playback ---"
  cat "$DEV"
else
  grep -A10 '^Playback:' "/proc/asound/card${CARD}/stream0"
fi
wait "$PID"
echo ""
echo "Done. If hw_ptr moved up and you heard nothing, the IEC box is not routing"
echo "USB playback to the jack you are using — adjust front-panel routing knobs."
