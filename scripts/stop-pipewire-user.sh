#!/usr/bin/env bash
set -euo pipefail

systemctl --user stop wireplumber.service pipewire-pulse.service pipewire.service || true
echo "Stopped user PipeWire/WirePlumber services."
echo "Restart with: systemctl --user start pipewire.service pipewire-pulse.service wireplumber.service"

