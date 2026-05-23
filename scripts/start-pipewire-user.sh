#!/usr/bin/env bash
set -euo pipefail

systemctl --user start pipewire.service pipewire-pulse.service wireplumber.service
echo "Started user PipeWire/WirePlumber services."

