#!/usr/bin/env bash
# Install bloodsiren ALSA + PipeWire config on Pop!_OS / Ubuntu (PipeWire).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> bloodsiren install from ${ROOT}"

mkdir -p "${HOME}/.config/wireplumber/wireplumber.conf.d"
mkdir -p "${HOME}/.config/pipewire/pipewire.conf.d"
mkdir -p "${HOME}/.config/bloodsiren"

chmod +x "${ROOT}/scripts/"*.sh

cp -f "${ROOT}/config/wireplumber/51-hifi-audio-dual.conf" \
  "${HOME}/.config/wireplumber/wireplumber.conf.d/"

cp -f "${ROOT}/config/pipewire/90-combine-judge-inputs.conf" \
  "${HOME}/.config/pipewire/pipewire.conf.d/"

if [[ ! -f "${HOME}/.config/bloodsiren/hub-ports.env" ]]; then
  echo "==> Detecting USB hub ports (first time)..."
  "${ROOT}/scripts/detect-hub-ports.sh" || true
  if [[ ! -f "${HOME}/.config/bloodsiren/hub-ports.env" ]]; then
    cp "${ROOT}/config/hub-ports.example.env" "${HOME}/.config/bloodsiren/hub-ports.env"
    echo "Edit ${HOME}/.config/bloodsiren/hub-ports.env with your hub port numbers."
  fi
fi

echo "==> Restarting PipeWire..."
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
sleep 2

echo "==> Generating ~/.asoundrc..."
# shellcheck source=/dev/null
source "${HOME}/.config/bloodsiren/hub-ports.env"
export HUB_PORT_BLOOD HUB_PORT_SIREN
"${ROOT}/scripts/refresh-bloodsiren.sh"

echo
echo "==> Verify"
"${ROOT}/scripts/identify-units.sh" || true
echo
echo "Install done. Next:"
echo "  ${ROOT}/scripts/test-input8.sh"
echo "  ${ROOT}/scripts/test-blood-output.sh"
echo "  ${ROOT}/scripts/fix-waveform-stereo-sum.sh   # if Waveform is installed"
echo
echo "Waveform ALSA:  in=bloodsiren_in  out=blood_mix_out  @ 48000 Hz"
echo "See README.md for full setup."
