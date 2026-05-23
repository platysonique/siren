#!/usr/bin/env bash
# Find which blood USB channel reaches your headphones / direct outs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
"${ROOT}/refresh-bloodsiren.sh" >/dev/null

python3 <<'PY'
import math, struct, wave
rate = 48000
dur = 2.0
freq = 880
for ch in range(4):
    path = f'/tmp/blood_test_ch{ch}.wav'
    n = int(rate * dur)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = bytearray()
        for i in range(n):
            sample = int(32767 * 0.85 * math.sin(2 * math.pi * freq * i / rate))
            frames += struct.pack('<h', sample)
        w.writeframes(frames)
PY

echo ""
echo "Blood output channel test (880 Hz, 2 sec each)"
echo "Listen on the blood unit headphones / front panel."
echo ""

for ch in 0 1 2 3; do
  echo ">>> Channel $ch — FL=$ch on 4ch map (FL FR RL RR)"
  aplay -D "blood_test_ch${ch}" -c 1 -r 48000 -f S16_LE "/tmp/blood_test_ch${ch}.wav"
  echo ""
done

echo "Also testing stereo blood_playback (both ears):"
python3 <<'PY'
import math, struct, wave
rate = 48000
dur = 2.0
freq = 660
path = '/tmp/blood_stereo_test.wav'
n = int(rate * dur)
with wave.open(path, 'w') as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(rate)
    frames = bytearray()
    for i in range(n):
        sample = int(32767 * 0.85 * math.sin(2 * math.pi * freq * i / rate))
        frames += struct.pack('<hh', sample, sample)
    w.writeframes(frames)
PY
aplay -D blood_playback /tmp/blood_stereo_test.wav
echo ""
echo "If you heard nothing on ALL tests: check the blood unit's front-panel"
echo "headphone/direct-out routing knobs — Linux only sees one 4ch USB stream."
