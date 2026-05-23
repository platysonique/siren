#!/usr/bin/env bash
# Reset Waveform ALSA prefs — split in/out avoids 256ch duplex bug
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
    match = re.fullmatch(r"wavein_channel (\d+)", name)
    if match:
        return int(match.group(1)) <= 8
    match = re.fullmatch(r"waveout_channel (\d+) \+ (\d+)", name)
    if match:
        return int(match.group(1)) == 1 and int(match.group(2)) == 2
    return True

def scrub_values(text: str) -> str:
    pattern = re.compile(r'  <VALUE name="([^"]+)">.*?</VALUE>\n', re.DOTALL)

    def repl(match: re.Match[str]) -> str:
        return match.group(0) if keep_value(match.group(1)) else ""

    return pattern.sub(repl, text)

content = scrub_values(content)
content = re.sub(
    r'(<DEVICESETUP[^>]*audioOutputDeviceName=")[^"]*(")',
    r"\1blood_playback\2",
    content,
)
content = re.sub(
    r'(<DEVICESETUP[^>]*audioInputDeviceName=")[^"]*(")',
    r"\1bloodsiren_in\2",
    content,
)
path.write_text(content, encoding="utf-8")
print(f"Updated {path} -> in=bloodsiren_in out=blood_playback")
PY
fi

echo ""
echo "Open Waveform → Settings → Audio Devices:"
echo "  1. Reset Input Devices"
echo "  2. Reset Output Devices"
echo "  3. Input:  bloodsiren_in"
echo "  4. Output: blood_playback"
echo "  5. Rate:   48000 Hz"
echo "  6. Hit Test on OUTPUT — you should hear a tone on blood headphones"
echo ""
echo "If still silent, quit Waveform and run:"
echo "  ${ROOT}/test-blood-outputs.sh"
