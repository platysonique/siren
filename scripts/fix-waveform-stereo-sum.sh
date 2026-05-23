#!/usr/bin/env bash
# Force Waveform to one stereo output bus (master mix on blood).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="${HOME}/.config/Tracktion/Waveform/Waveform.settings"

pkill -x Waveform13 2>/dev/null || true
sleep 1

"${ROOT}/refresh-bloodsiren.sh"

if [[ -f "${SETTINGS}" ]]; then
  cp "${SETTINGS}" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"

  python3 <<'PY'
import re
from pathlib import Path

path = Path.home() / ".config/Tracktion/Waveform/Waveform.settings"
content = path.read_text(encoding="utf-8")

def keep_value(name: str) -> bool:
    m = re.fullmatch(r"wavein_channel (\d+)", name)
    if m:
        return int(m.group(1)) <= 8
    m = re.fullmatch(r"waveout_channel (\d+) \+ (\d+)", name)
    if m:
        return int(m.group(1)) == 1 and int(m.group(2)) == 2
    return True

pattern = re.compile(r'  <VALUE name="([^"]+)">.*?</VALUE>\n', re.DOTALL)
content = pattern.sub(lambda m: m.group(0) if keep_value(m.group(1)) else "", content)

content = re.sub(
    r'(<DEVICESETUP[^>]*audioOutputDeviceName=")[^"]*(")',
    r"\1blood_mix_out\2",
    content,
)
content = re.sub(
    r'(<DEVICESETUP[^>]*audioInputDeviceName=")[^"]*(")',
    r"\1bloodsiren_in\2",
    content,
)

path.write_text(content, encoding="utf-8")
print("Waveform -> in=bloodsiren_in out=blood_mix_out, waveout 1+2 only")
PY
fi

echo ""
echo "  1. Reset Input Devices  → pick bloodsiren_in, enable channels 1–8"
echo "  2. Reset Output Devices → pick blood_mix_out, enable channel 1+2 only"
echo "  Master fader up; all tracks routed to (default audio output)"
echo ""
echo "On the siren box: turn DOWN direct/local monitor so judges 5-8"
echo "  are not heard only on that unit's headphones."
echo ""
echo "CLI check: speaker-test -D blood_mix_out -c 2 -r 48000 -t sine -l 1"
