#!/usr/bin/env bash
set -euo pipefail

RATE="${RATE:-48000}"
BLOCK="${BLOCK:-256}"

command -v pw-cli >/dev/null || { echo "pw-cli not found"; exit 1; }
command -v pw-link >/dev/null || { echo "pw-link not found"; exit 1; }

echo "Starting PipeWire services if needed..."
systemctl --user start pipewire.service pipewire-pulse.service wireplumber.service

echo "Requested JACK-ish settings:"
echo "  rate=$RATE block=$BLOCK"
echo
echo "For Waveform:"
echo "  launch with scripts/launch-waveform-pwjack.sh"
echo "  use JACK backend if Waveform exposes it"
echo
echo "Available capture ports containing AUDIO/blood/siren:"
pw-link -i | grep -Ei 'AUDIO|blood|siren|capture|input' || true
echo
echo "Available playback ports containing AUDIO/blood/siren:"
pw-link -o | grep -Ei 'AUDIO|blood|siren|playback|output' || true
echo
echo "Manual routing after Waveform is open:"
echo "  pw-link '<blood capture FL>' '<Waveform input 1>'"
echo "  pw-link '<blood capture FR>' '<Waveform input 2>'"
echo "  pw-link '<blood capture RL>' '<Waveform input 3>'"
echo "  pw-link '<blood capture RR>' '<Waveform input 4>'"
echo "  pw-link '<siren capture FL>' '<Waveform input 5>'"
echo "  pw-link '<siren capture FR>' '<Waveform input 6>'"
echo "  pw-link '<siren capture RL>' '<Waveform input 7>'"
echo "  pw-link '<siren capture RR>' '<Waveform input 8>'"
echo "  pw-link '<Waveform out L>' '<blood playback FL>'"
echo "  pw-link '<Waveform out R>' '<blood playback FR>'"

